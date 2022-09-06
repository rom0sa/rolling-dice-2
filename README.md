# rolling-dice
Is a simple dice a application that roll 3 6 sided die. Written in Python and terraform to deploy required AWS Service.
## Requirements
### Python modules
[random](https://docs.python.org/3/library/random.html)
[boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
### AWS 
[LambdaFunction](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
[AmazonAPIGateway](https://aws.amazon.com/api-gateway/)
## Configuration
- Lambda Function
  - Create a role for the Lambda with approriate permission
  - Create the function selecting Python as runtime
  - Deploy your code
- API Gateway
  - Create the API Gateway with REST API protocol
  - Add a Resource path
  - Add a Method for the resource
  - Add query parameters in Method Request
  - Set the Lambda Function as integration poing in Integration Request

![workflow](https://dice-diagram.s3.us-west-2.amazonaws.com/dice.draw.svg.svg)