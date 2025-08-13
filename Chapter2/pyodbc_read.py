import pyodbc

# Example of connecting to an IBM i system using pyodbc with Username and Password
# myIBMi = "myIBMi"
# username = "username"
# password = "password"
# connection = pyodbc.connect(f'DRIVER={{IBM i Access ODBC Driver}};SYSTEM={myIBMi};UID={username};PWD={password}')

connstring = 'DSN=*LOCAL;CommitMode=0;'

try:
    # Establish a connection to the database
    connection = pyodbc.connect(connstring)
    print("Connected to DB2 successfully.")

    # Create a cursor from the connection
    cursor = connection.cursor() 

    # Execute a SELECT Query
    cursor.execute("select * from qiws.qcustcdt")

    # Get column names
    column_names = [desc[0] for desc in cursor.description]

    # Print header row (pipe-delimited)
    print('|'.join(column_names))

    # Fetch all rows from the executed query
    rows = cursor.fetchall()

    for row in rows:
        # Convert each row to a pipe-delimited string
        print('|'.join(str(value) for value in row))

except Exception as e:
    print("Error:", e)

finally:
    # Always close the connection
    connection.close()    
