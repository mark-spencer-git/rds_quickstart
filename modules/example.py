import boto3
import psycopg2

def get_rds_config():
    ssm = boto3.client('ssm', region_name='us-east-1')

    def get_param(name, decrypt=False):
        return ssm.get_parameter(Name=name, WithDecryption=decrypt)['Parameter']['Value']

    return {
        'host':     get_param('/myapp/rds/endpoint'),
        'port':     int(get_param('/myapp/rds/port')),
        'dbname':   get_param('/myapp/rds/db_name'),
        'user':     'dbadmin',
        'password': get_param('/myapp/rds/password', decrypt=True)
    }

def main():
    config = get_rds_config()
    conn = psycopg2.connect(**config)
    print(conn)

if __name__ == "__main__":
    main()