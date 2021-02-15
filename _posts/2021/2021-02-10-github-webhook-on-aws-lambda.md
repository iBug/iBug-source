---
title: "Setting up a GitHub webhook on AWS Lambda"
tags: github aws
redirect_from: /p/41

published: false
---

Last month I set up my own Telegram bot for GitHub event notification. To receive GitHub events via webhook, a receiver is needed. True, it isn't hard to write a [Flask][flask] or [Sinatra][sinatra] server and throw the whole thing onto a VPS, but thinking about the complexity and maintenance efforts, serverless platforms like AWS Lambda smells like a better fit. So I decided to take this opportunity to begin my exploration to "the serverless industry".

  [flask]: https://palletsprojects.com/p/flask/
  [sinatra]: http://sinatrarb.com/

## Setting up AWS Lambda {#aws-lambda}

I have had an AWS account for years, so I'll skip the sign-up process in this article and head straight to [AWS Management Console][aws-console]. 

  [aws-console]: https://console.aws.amazon.com/

Locate the [**Lambda**][lambda-home] entry in the list of AWS services. It's in the first group so should be easy to spot.

  [lambda-home]: https://console.aws.amazon.com/lambda/home

![AWS Management Console Home](/image/aws/console-home-1.png)

And then we create a new Lambda function, selecting Python 3.8 as the runtime environment

![Create new Lambda function](/image/aws/lambda-create-function-1.png){: .border }

After clicking "Create", you'll be brought to the edit page of that function, with the following code filled in as a starting point.

```python
import json

def lambda_handler(event, context):
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
```

We don't know what this code can do for now, so let's put it aside and turn to the API Gateway part, since eventually we'll use it as the webhook receiver endpoint.

## Setting up AWS API Gateway {#api-gateway}

Open the [AWS API Gateway console][apigw-home] and click **Create API** on the top right.

  [apigw-home]: https://console.aws.amazon.com/apigateway/main

![Create API](/image/aws/api-gateway-new-1.png){: .border }

On the next screen, we add our Lambda function created earlier as an integration here.

![Configure integrations](/image/aws/api-gateway-new-2.png){: .border }

![Configure routes (1)](/image/aws/api-gateway-routes-1.png){: .border }

![Configure routes (2)](/image/aws/api-gateway-routes-2.png){: .border }

```console
ubuntu@iBug-Server:~ $ curl https://nad73szpz7.execute-api.us-east-1.amazonaws.com/
"Hello from Lambda!"
ubuntu@iBug-Server:~ $
```