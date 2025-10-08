**free
Ctl-Opt option(*nodebugio:*srcstmt:*nounref) Main(Main) dftactgrp(*no)
   text('Web Server RPG Handler Program');

// The main procedure that will listen for incoming requests
Dcl-Proc Main;
  Dcl-Pi *N;
    pMethod CHAR(10) const;
    pRequestData CHAR(32000) const;
    pResponseData CHAR(32000);
  End-Pi;

  Dcl-S vJsonString CHAR(32000);
  Dcl-S vApp VARCHAR(50);
  Dcl-S vAction VARCHAR(50);
  // Dcl-S vRequestData SQLTYPE(CLOB:500000);

  Exec Sql
    Set Option commit = *none;

    // If QueryString is blank display main page from the IFS
  If pRequestData = '';
    pResponseData = '{"data": null}';
    Return;
  Else;
    Exec Sql
      SELECT upper(jt.app)
              ,upper(jt.action)
      INTO :vApp
          ,:vAction
          FROM JSON_TABLE(trim(:pRequestData),
              'lax $'
              COLUMNS (
                  app    VARCHAR(50) PATH 'lax $.app',
                  action VARCHAR(50) PATH 'lax $.action'
              )
          ) AS jt;

    If sqlcod <> 0;
      pResponseData = '{ "success": false, "message": "Invalid JSON format" }';
      Return;
    EndIf;
  EndIf;

  If %upper(pMethod) = 'GET ';
    Select;
      When vApp = 'PRODUCT' and vAction = 'GETPRODUCTLIST';
        // Call the procedure to get the Product List in JSON format
        vJsonString = GetProductList();
        pResponseData = vJsonString;
      When vApp = 'PRODUCT' and vAction = 'GETPRODUCT';
        // Call the procedure to get the Product List in JSON format
        vJsonString = GetProduct(pRequestData);
        pResponseData = vJsonString;
      Other;
        pResponseData = '{"success": false, "message": "Unknown Action Sent"}';
    EndSl;
  EndIf;

  If %upper(pMethod) = 'POST';
    Select;
      When vApp = 'PRODUCT' and vAction = 'DELETE';
        vJsonString = DeleteProduct(pRequestData);
        pResponseData = vJsonString;
      When vApp = 'PRODUCT' And (vAction = 'UPDATEPRODUCT');
        vJsonString = UpdateProduct(pRequestData : vAction);
        pResponseData = vJsonString;
      When vApp = 'PRODUCT' And (vAction = 'ADDPRODUCT');
        vJsonString = AddProduct(pRequestData : vAction);
        pResponseData = vJsonString;
      Other;
        pResponseData = '{"success": false, "message":' +
         pMethod + '/' + vAction + '" Unknown Action Sent"}';
    EndSl;
  EndIf;

End-Proc;

Dcl-Proc GetProductList;
  Dcl-Pi *N CHAR(32000);
  End-Pi;

  Dcl-S jsonString CHAR(32000);
  Dcl-S jsonStringClob SQLTYPE(CLOB:32000);

  Exec Sql
  Select Cast(
      Json_Object(
        'data' Value (Json_Arrayagg(
          Json_Object(
            'ProductNumber'  Value rtrim(product_number)
            ,'Description' Value Rtrim(description)
            ,'Cost' Value Cost
            ,'UnitOfMeasure' Value Rtrim(unit_of_measure)
            ,'Category' Value Rtrim(category)
          )
        ))
      ) As Clob(32000))
    Into :jsonstringclob
    From rthompson1.product_master;

  JsonString = JsonStringClob_Data;
  Return JsonString;
End-Proc;

Dcl-Proc GetProduct;
  Dcl-Pi *N CHAR(32000);
    pRequestData CHAR(32000) const;
  End-Pi;

  Dcl-S jsonString CHAR(32000);
  Dcl-S jsonStringClob SQLTYPE(CLOB:32000);
  Dcl-S vProductNumber VARCHAR(20);

  Exec Sql
    SELECT jt.productnumber
    INTO :vProductNumber
    FROM JSON_TABLE(trim(:pRequestData),
        'lax $'
        COLUMNS (
            productnumber VARCHAR(20) PATH 'lax $.productnumber'
        )
    ) AS jt;

  If sqlcod <> 0;
    jsonString = '{"success": false, "message": "Invalid JSON format"}';
    Return jsonString;
  EndIf;

  Exec Sql
   Select Cast(
      Json_Object(
        'data' Value
          Json_Object(
            'ProductNumber'  Value rtrim(product_number)
            ,'Description' Value Rtrim(description)
            ,'Cost' Value Cost
            ,'UnitOfMeasure' Value Rtrim(unit_of_measure)
            ,'Category' Value Rtrim(category)
          )
        )
       As CLOB(32000))
    Into :jsonstringclob
    From rthompson1.product_master
    Where product_number = :vProductNumber
    Fetch First Row Only;

  If sqlcod = 100;
    jsonString = '{"success": false, "message": "Product not found"}';
    Return jsonString;
  EndIf;

  If sqlcod <> 0;
    jsonString = '{"success": false, "message": "Error Occurred while retrieving product"}';
    Return jsonString;
  EndIf;

  JsonString = JsonStringClob_Data;
  Return JsonString;
End-Proc;

Dcl-Proc DeleteProduct;
  Dcl-Pi *N CHAR(32000);
    pRequestData CHAR(32000) const;
  End-Pi;

  Dcl-S vProductNumber VARCHAR(20);
  Dcl-S vJsonResponse VARCHAR(32000);

  Exec Sql
    SELECT jt.productnumber
    INTO :vProductNumber
    FROM JSON_TABLE(trim(:pRequestData),
        'lax $'
        COLUMNS (
            productnumber VARCHAR(20) PATH 'lax $.productnumber'
        )
    ) AS jt;

  If sqlcod <> 0;
    vJsonResponse = '{"success": false, "message": "Invalid JSON format"}' ;
    Return vJsonResponse;
  EndIf;

  // Perform the delete operation
  Exec Sql
    DELETE FROM rthompson1.product_master
    WHERE product_number = :vProductNumber;

  If sqlcod = 0;
    vJsonResponse = '{"success": true, "message": "Successfully deleted product: '
            + %trim(vProductNumber) + '" }';
  Else;
    vJsonResponse = '{"success": false, "message": "Failed to delete product: '
            + %trim(vProductNumber) + '" }';
  EndIf;

  Return vJsonResponse;
End-Proc;

Dcl-Proc UpdateProduct;
  Dcl-Pi *N CHAR(32000);
    pRequestData CHAR(32000) const;
    pAction VARCHAR(50) const;
  End-Pi;

  Dcl-S vJsonResponse  VARCHAR(32000);
  Dcl-S vProductNumber VARCHAR(20);
  Dcl-S vDescription   VARCHAR(100);
  Dcl-S vCost          PACKED(10:2);
  Dcl-S vUnitOfMeasure VARCHAR(10);
  Dcl-S vCategory      VARCHAR(50);
  Dcl-S vExists        IND INZ(*Off);

  Exec Sql
    SELECT jt.productnumber
          ,jt.descriptieon
          ,jt.cost
          ,jt.unitofmeasure
          ,jt.category
    INTO :vProductNumber
        ,:vDescription
        ,:vCost
        ,:vUnitOfMeasure
        ,:vCategory
    FROM JSON_TABLE(trim(:pRequestData),
        'lax $'
        COLUMNS (
            productnumber VARCHAR(20)   PATH 'lax $.ProductNumber',
            descriptieon   VARCHAR(100)  PATH 'lax $.Description',
            cost          DECIMAL(10,2) PATH 'lax $.Cost',
            unitofmeasure VARCHAR(10)   PATH 'lax $.UnitOfMeasure',
            category      VARCHAR(10)   PATH 'lax $.Category'
        )
    ) AS jt;

  If sqlcod <> 0;
    vJsonResponse = '{"success": false, "message": "Invalid JSON format"}' ;
    Return vJsonResponse;
  EndIf;

  // Check to see if it exists
  Exec Sql
    Select 1
      Into :vExists
    From rthompson1.product_master
    Where product_number = :vProductNumber
    Fetch First Row Only;

  If sqlcod = 100 or Not vExists;
    vJsonResponse = '{"success": false, "message": "Product not found"}';
    Return vJsonResponse;
  EndIf;

  // Edit the product records
  If EditProduct(vProductNumber
                :vDescription
                :vCost
                :vUnitOfMeasure
                :vCategory
                :vJsonResponse
                ) = *On;

    Return vJsonResponse;
  EndIf;

  Exec Sql
    UPDATE rthompson1.product_master
    SET description = :vDescription
      ,cost = :vCost
      ,unit_of_measure = :vUnitOfMeasure
      ,category = :vCategory
    WHERE product_number = :vProductNumber;

  If sqlcod = 0;
      vJsonResponse = '{"success": true, "message": "Successfully updated product: '
              + %trim(vProductNumber) + '" }';
  Else;
      vJsonResponse = '{"success": false, "message": "Failed to update product: '
              + %trim(vProductNumber) + '" }';
  EndIf;

  Return vJsonResponse;
End-Proc;

Dcl-Proc EditProduct;
  Dcl-Pi *N IND;  // Returns *On if there is an error
    pProductNumber VARCHAR(20) const;
    pDescription VARCHAR(100) const;
    pCost PACKED(10:2) const;
    pUnitOfMeasure VARCHAR(10) const;
    pCategory VARCHAR(50) const;
    pJsonResponse VARCHAR(32000);
  End-Pi;

  Dcl-S vErrorMessage VARCHAR(2000);

  If pDescription = '';
    vErrorMessage = 'Description cannot be blank ' + '\n';
  EndIf;

  If pCost < 0;
    vErrorMessage += 'Cost cannot be negative' + '\n';
  EndIf;

  If pUnitOfMeasure = '';
    vErrorMessage += 'Unit of Measure cannot be blank' + '\n';
  EndIf;

  If pCategory = '';
    vErrorMessage += 'Category cannot be blank' + '\n';
  EndIf;

  If vErrorMessage <> '';
    pJsonResponse = '{"success": false, "message": "' + vErrorMessage + '"}';
    Return *On;
  EndIf;
  Return *Off;
End-Proc;

Dcl-Proc AddProduct;
  Dcl-Pi *N CHAR(32000);
    pRequestData CHAR(32000) const;
    pAction VARCHAR(50) const;
  End-Pi;

  Dcl-S vJsonResponse  VARCHAR(32000);
  Dcl-S vProductNumber VARCHAR(20);
  Dcl-S vDescription   VARCHAR(100);
  Dcl-S vCost          PACKED(10:2);
  Dcl-S vUnitOfMeasure VARCHAR(10);
  Dcl-S vCategory      VARCHAR(50);
  Dcl-S vExists        IND INZ(*Off);

  Exec Sql
    SELECT jt.productnumber
          ,jt.descriptieon
          ,jt.cost
          ,jt.unitofmeasure
          ,jt.category
    INTO :vProductNumber
        ,:vDescription
        ,:vCost
        ,:vUnitOfMeasure
        ,:vCategory
    FROM JSON_TABLE(trim(:pRequestData),
        'lax $'
        COLUMNS (
            productnumber VARCHAR(20)   PATH 'lax $.ProductNumber',
            descriptieon   VARCHAR(100)  PATH 'lax $.Description',
            cost          DECIMAL(10,2) PATH 'lax $.Cost',
            unitofmeasure VARCHAR(10)   PATH 'lax $.UnitOfMeasure',
            category      VARCHAR(10)   PATH 'lax $.Category'
        )
    ) AS jt;

  If sqlcod <> 0;
    vJsonResponse = '{"success": false, "message": "Invalid JSON format"}' ;
    Return vJsonResponse;
  EndIf;

  // Check to see if it exists
  Exec Sql
    Select 1
      Into :vExists
    From rthompson1.product_master
    Where product_number = :vProductNumber
    Fetch First Row Only;

  If sqlcod = 0 or vExists;
    vJsonResponse = '{"success": false, "message": "Product Number already exists"}';
    Return vJsonResponse;
  EndIf;

  // Edit the product records
  If EditProduct(vProductNumber
                :vDescription
                :vCost
                :vUnitOfMeasure
                :vCategory
                :vJsonResponse
                ) = *On;

    Return vJsonResponse;
  EndIf;

  Exec Sql
    INSERT INTO rthompson1.product_master 
      (product_number
      ,description
      ,cost
      ,unit_of_measure
      ,category) 
    VALUES 
      (:vProductNumber
      ,:vDescription
      ,:vCost
      ,:vUnitOfMeasure
      ,:vCategory);

  If sqlcod = 0;
      vJsonResponse = '{"success": true, "message": "Successfully added product: '
              + %trim(vProductNumber) + '" }';
  Else;
      vJsonResponse = '{"success": false, "message": "Failed to add product: '
              + %trim(vProductNumber) + '" }';
  EndIf;

  Return vJsonResponse;
 
End-Proc;