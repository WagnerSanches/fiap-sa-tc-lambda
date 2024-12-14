import os
import json
import jwt
import pymysql
import boto3

# Database connection parameters
RDS_HOST = os.environ['RDS_HOST']  # RDS endpoint
RDS_USER = os.environ['RDS_USER']  # RDS username
RDS_PASSWORD = os.environ['RDS_PASSWORD']  # RDS password
RDS_DB_NAME = os.environ['RDS_DB_NAME']  # RDS database name

# JWT secret key from environment variable
JWT_SECRET = os.environ['JWT_TOKEN']

def lambda_handler(event, context):
    # Extract user and password from the event payload
    user = event.get('user')
    password = event.get('password')

    if not user or not password:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'User and password are required'})
        }

    # Connect to the RDS database
    try:
        connection = pymysql.connect(
            host=RDS_HOST,
            user=RDS_USER,
            password=RDS_PASSWORD,
            database=RDS_DB_NAME
        )
        
        with connection.cursor() as cursor:
            sql = "SELECT COUNT(*) FROM staff WHERE username = %s AND password = %s"
            cursor.execute(sql, (user, password))
            result = cursor.fetchone()

            if result[0] == 1:
                token = jwt.encode({'user': user}, JWT_SECRET, algorithm='HS256')
                return {
                    'statusCode': 200,
                    'body': json.dumps({'token': token})
                }
            else:
                return {
                    'statusCode': 401,
                    'body': json.dumps({'message': 'Invalid credentials'})
                }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': str(e)})
        }
    finally:
        if connection:
            connection.close()
