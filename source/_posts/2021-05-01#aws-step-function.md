---
title: AWS Step Function
date: 2021-05-01 19:52:52
category: "Architecture"
tags:
- AWS
- Serverless
thumbnail: /images/aws-step-function.png
featured: true
---

Our client recently has a deployment system that has been in use for more than 10 years and wants to migrate to the cloud, this blog shows how we migrate it step by step from a huge single application to serverless by AWS Step funtion.

<!-- more -->

# Why Step Function

The deployment system is a legacy system which has been used for more than ten years, it contain a complex logic for deployment, include testing, validation, authorization and auditing features. After multi times switch owner teams, the code become complex and hard to understand, however customers still keep asking add new features. On the other hand, even the system is too complex to understand, the system is robust after 10 years maintenance, it has solved a lot of small problems, so the team can not build a whole new system to replace it easily.

A deployment system's core feature is process control, it can consider as a pipeline, customers can build, test, deploy there code via the pipeline, and the state of the pipeline can switch between INIT, DEPLOYING, PENDING, SUCCESS/FAILED, in another word, ths system's core feature is a state machine.

[AWS Step function](https://aws.amazon.com/step-functions/) is a service help manage complex workflow. User can create statemachines as a workflow, each step of the workflow called a state, Task can be lambda function, worker in different computing resources(EC2, ECS, etc), or simple state control by aws step function services like waiting, pass, choice, etc. 

AWS Step Function is compatible with local workers and lambdas, integrate legacy system with AWS Step function can help migrate from single application to serverless architecture step by step.

 # How To Migrate

To demonstrate how step function working with local [activities](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-activities.html) I created a [demo](https://github.com/ADU-21/step-function-demo) by using Google Guice. Below steps showing how we migrate this service to step function step by step.

### Step#1 Decouple deployment steps

Process management in legacy system is controlled by method calls, it's complex and has deep call level. The first step is refactor the complex flow and decouple as diffferent activities, eact activite map to a step in the deployment flow, like pre-testing, validation, monitoring, etc. 

### Step#2 Create Step function State Machine

After identify steps in the deployment flow, we can draw a simple diagram shows how dpeloyment process, for example, the flow in the demo looks like this:

![](/images/aws-step-function.png)

The deployment start at deployment state, once it's success, flow going to success state and send notification there, once it failed(exception thrown), it's going to failed state.

AWS Step function using [Amazon States Language](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html) to define stage machin, the flow shown in the diagram will look like this in the definition:

```json
{
  "Comment": "Deployment StateMachine",
  "StartAt": "Deployment",
  "States": {
    "Deployment": {
      "Type": "Task",
      "Resource": "<Deployment Activity ARN>",
      "Next": "Successed",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Failed",
          "ResultPath": "$.error"
        }
      ]
    },
    "Successed": {
      "Type": "Task",
      "Resource": "<Success Activity ARN>",
      "End": true
    },
    "Failed": {
      "Type": "Task",
      "Resource": "Failed Activity ARN",
      "End": true
    }
  }
}
```

The input data will all passed to next state as json, the `Catch` element means when there is Exception thrown in the deployment state, the next state will be `Failed` and exception will pass as input into that state.

### Step#3 Poll State

Refer to [AWS Step Function:Activities Document](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-activities.html), once statemachine excute, the activity worker has to poll for a task by using [GetActivityTask](https://docs.aws.amazon.com/step-functions/latest/apireference/API_GetActivityTask.html), once the response is not null, it means a activty should execute:

```java
GetActivityTaskResult activityTaskResult = awsStepFunctionHandler.getActivityTaskResult(awsStepFunctionActivityARN);
        if (activityTaskResult != null && activityTaskResult.getTaskToken() != null) {
            # Step function execute
        } else {
            # Continue polling
        }
```

### Step#4 Activity Execution

Each activity has `input` and `output`, The input value in the `GetActivityTaskResult` is a json string, the first step in execution is convert json string to an input object the pass it to activity customized executeTask() function, if success, pass output object to json string and call [sendTaskSuccess](https://docs.aws.amazon.com/step-functions/latest/apireference/API_SendTaskSuccess.html) api, when unexpected exception thrown, call [sendTaskFailure](https://docs.aws.amazon.com/step-functions/latest/apireference/API_SendTaskFailure.html) api. To reuse those logic I craeted an abstract class and let all activities extend it:

```java
public abstract class AbstractStepFunctionActivity<INPUT, OUTPUT> {
  
      protected abstract OUTPUT executeTask(INPUT input);
  
      public void execute(GetActivityTaskResult activityTaskResult) {
        String taskToken = activityTaskResult.getTaskToken();
        try {
            INPUT input = gson.fromJson(activityTaskResult.getInput(), inputClass);
            OUTPUT output = executeTask(input);
            sendTaskSuccess(taskToken, output);
        } catch (Exception e) {
            sendTaskFailure(taskToken, e);
        }
    }
}
```

### Step#5 Exception handling

As Step function definition defined in first step, when deployment state failed, the Failed state will executed with exception as input:

```json
"Catch": [
  {
    "ErrorEquals": [
      "States.ALL"
    ],
    "Next": "Failed",
    "ResultPath": "$.error"
  }
]
```

It can tested by input an invalid deployment id:

![](/images/aws-step-function-failed-flow.png)

### Step#6 Finalize Main Function

The main class looks like this:

```java
@Log4j2
@RequiredArgsConstructor(onConstructor = @__(@Inject))
public class StepFunctionDemoApplication {
    private final StepFunctionObserver stepFunctionObserver;
    private final DeploymentService deploymentService;

    public static void main(String[] args) {
        Injector injector = Guice.createInjector(new AWSStepFunctionModule(), new PostConstructModule());
        StepFunctionDemoApplication application = injector.getInstance(StepFunctionDemoApplication.class);
        application.start();
    }

    private void start() {
        deploymentService.executeDeployment();
    }
}
```

The `StepFunctionObserver` is response for start the observer thread pool to poll activitise by `@PostConstruct` annotation, `DeploymentService` response for execute aws step function by call [StartExecution](https://docs.aws.amazon.com/step-functions/latest/apireference/API_StartExecution.html), when observer thread poll find the execution task, submit to `stepFunctionActivityExecutor` thread poll to execute.

# Conclusion

By using AWS step function, it itegrate with local funcstion as activity worker, on the other hand, client can add new state using Lambda, also can migrate local activity to Lambda one by one, eventually single application can migrate to serverless architecture in the cloud, with minimal risk. 