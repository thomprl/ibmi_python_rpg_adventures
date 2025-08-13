import pyodbc
from tabulate import tabulate

# Example of connecting to an IBMi system using pyodbc with Username and Password
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

    # Fetch all rows from the executed query
    rows = cursor.fetchall()

    # Print the rows in a text table
    print(tabulate(rows, headers=column_names, tablefmt="grid"))

except Exception as e:
    print("Error:", e)

finally:
    # Always close the connection
    connection.close()    
