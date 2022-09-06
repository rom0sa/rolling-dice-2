import random
import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table('dice_results')

#rollCount = 10
#dieSidesCount = 6
#dieMinValue = 1

def dice_roll(dieSidesCount):
    diceRoll = random.randint(1,dieSidesCount)
    return diceRoll
    
def lambda_handler(event, context):
    statistics = []
    helper = 0
    myevent = print(event)
    ##Still working on this as it's not working as expected. If query paramater was declare it should set the value, if not set a default value. 
    if any('rollCount' in s for s in event):
        rollCount = int(event["params"]["querystring"]["rollCount"])
    else:
        rollCount = 100
    if any('dieSidesCount' in s for s in event):
        dieSidesCount = int(event["params"]["querystring"]["dieSidesCount"]) 
    else:
        dieSidesCount = 6
    if any('dieCount' in s for s in event):
        dieCount = int(event["params"]["querystring"]["dieCount"]) 
    else:
        dieCount = 3
    print("Number of roll %d, number of die %d and number of sides of die %d" % (rollCount, dieCount, dieSidesCount))
    print("Rolling 3 dice")
    sims = str(rollCount)
    if rollCount >= 1:
        for i in range(1,rollCount+1):
            roll_total = 0
            for x in range(1,dieCount+1):
            x = dice_roll(max)
            roll_total += x 

            stat = '%ds'% roll_total
            #Insert the data in dynamodb. If the results exist in the table, increment by one if not add it as a new item with a value of 0 + 1
            perform_update = table.update_item(
                        Key={'dice_sum': stat},
                        UpdateExpression="SET occurrence = if_not_exists(occurrence, :start) + :increase",
                        ExpressionAttributeValues={
                            ':increase': 1,
                            ':start': 0
                        },
                      ReturnValues="UPDATED_NEW"
                      )
            #This is used in Assignment one to get the number of occurences per results. It is reused to add the rollCount as simulation.
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
    
    
    
    for item in statistics: 
        update_sims = table.update_item(
            Key={
                'dice_sum': item[0],
            },
            UpdateExpression="SET #rolls = if_not_exists(#rolls, :start) + :increase",
            ExpressionAttributeValues={
                ':increase': 1,
                ':start': 0,
            },
            ExpressionAttributeNames={
                '#rolls': sims,
            },
        ReturnValues="UPDATED_NEW"
            )
    
    relativeDistribution()    
    response = table.scan()
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': response
    }
    

#Compute for relative distribution    
def relativeDistribution():
    tableparamOccurrence = {'ProjectionExpression':'occurrence'}
    tableparamDiceSum = {'ProjectionExpression':'dice_sum'}
    allDiceSum = table.scan(**tableparamDiceSum)
    allOccurrence = table.scan(**tableparamOccurrence)
    allDice = allDiceSum
    allItems = allOccurrence
    dice = allDice['Items']
    occur = allItems['Items']
    total_occurrence = 0
    #Sum all occurences of dice results
    for i in occur:
        mynum = i['occurrence']
        total_occurrence += mynum
    
    #Get the occurences value per item then divide it by the total_occurence to get the relative distribution.
    ##I tried to do this during the first update_item but dynamodb UpdateExpression does not yet support division.
    for diceSum in dice:
        getItem = table.get_item(
        Key={
            'dice_sum': diceSum['dice_sum'],
        }
        )
        occurValue = int(getItem['Item']['occurrence'])
        relativeValue = (occurValue / float(total_occurrence)) * 100
        percentageRV = '{:.2f}'.format(relativeValue)
        #percentageRV = '%d%%' % format_percent
        update_rv = table.update_item(
            Key={
                'dice_sum': diceSum['dice_sum'],
            },
            UpdateExpression="SET percentRelativeDistribution = :rdValue",
            ExpressionAttributeValues={
                ':rdValue': percentageRV
            },
        ReturnValues="UPDATED_NEW"
            )