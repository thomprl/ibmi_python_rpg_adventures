import pyodbc
connstring = 'DSN=*LOCAL;CommitMode=0;'
try:
    conn = pyodbc.connect(connstring)
    print("Connected to the DB2")

    # Create a variable to hold the output parameter
    conn.execute("CREATE OR REPLACE VARIABLE RTHOMPSON1.OUT_PARM CHAR(200) CCSID 1208 DEFAULT ''")
    # Set the output parameter value to the job name of the current job
    conn.execute("SET RTHOMPSON1.OUT_PARM = qsys2.job_name")
    # Fetch the value in our variable to get the job name running this Python Program
    # This can be handy if needing to debug the program
    data = conn.execute("VALUES(RTHOMPSON1.OUT_PARM)").fetchval()

    # Print the job name
    print(f"Output Parameter Value: {data}")
   
    # Reset the output parameter to an empty string before calling the stored procedure
    conn.execute("SET RTHOMPSON1.OUT_PARM = ''")

    # Define the stored procedure call
    sql = "{CALL RTHOMPSON1.EXAMPLE1(?, RTHOMPSON1.OUT_PARM)}"
    # Input parameter value
    in_parm = "IBMi"
    # Define the parameters 
    parms = (in_parm)

    # Bind parameters
    conn.execute(sql, parms)
    
    # Fetch the output parameter value
    data = conn.execute("VALUES(RTHOMPSON1.OUT_PARM)").fetchval()
    # Print the output parameter value
    print(f"Output Parameter Value: {data}") 

except pyodbc.Error as e:
    print(f"Error: {e}")

finally:
    # Close cursor and connection
    conn.close()
