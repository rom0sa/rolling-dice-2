import random
import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table('dice_results')

#rollCount = 10
#dieMaxValue = 6
#dieMinValue = 1
def dice_roll():
    diceRoll = random.randint(dieMinValue,dieMaxValue)
    return diceRoll
    
def lambda_handler(event, context):
    statistics = []
    helper = 0
    myevent = print(event)
    if any('rollCount' in s for s in event):
        rollCount = int(event["params"]["querystring"]["rollCount"])
    else:
        rollCount = 100
    if any('dieMinValue' in s for s in event):
        dieMinValue = int(event["params"]["querystring"]["dieMinValue"]) 
    else:
        dieMinValue = 1
    if any('dieMaxValue' in s for s in event):
        dieMaxValue = int(event["params"]["querystring"]["dieMaxValue"]) 
    else:
        dieMaxValue = 6
    print("Number of roll %d, die minimum value %d and die maximum value %d" % (rollCount, dieMinValue, dieMaxValue))
    print("Rolling 3 dice")
    sims = str(rollCount)
    if rollCount >= 1:
        for i in range(1,rollCount+1):
            die1 = random.randint(dieMinValue,dieMaxValue)
            die2 = random.randint(dieMinValue,dieMaxValue)
            die3 = random.randint(dieMinValue,dieMaxValue)
            roll_total = die1 + die2 + die3
            stat = '%ds'% roll_total
            perform_update = table.update_item(
                        Key={'dice_sum': stat},
                        UpdateExpression="SET occurrence = if_not_exists(occurrence, :start) + :increase",
                        ExpressionAttributeValues={
                            ':increase': 1,
                            ':start': 0
                        },
                      ReturnValues="UPDATED_NEW"
                      )
            final = [stat,1]
            if len(statistics) > 0:
                for i in statistics:
                    if stat in i:
                        i[1] += 1
                        helper = 1
                        break
                if helper == 0:
                    statistics.append(final)
                helper = 0
            else:
                statistics.append(final)
    response = table.scan()
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': response
    }