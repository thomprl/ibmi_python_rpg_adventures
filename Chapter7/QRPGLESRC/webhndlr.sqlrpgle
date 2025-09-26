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
      Other;
        pResponseData = '{"success": false, "message": "Unknown Action Sent"}';
    EndSl;
  EndIf;

  If %upper(pMethod) = 'POST';
    Select;
      When vApp = 'PRODUCT' and vAction = 'DELETE';
        vJsonString = DeleteProduct(pRequestData);
        pResponseData = vJsonString;
      Other;
        pResponseData = '{"success": false, "message": "Unknown Action Sent"}';
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

Dcl-Proc DeleteProduct;
  Dcl-Pi *N CHAR(32000);
    pRequestData CHAR(32000) const;
  End-Pi;

  Dcl-S vProductNumber VARCHAR(50);
  Dcl-S vJsonResponse CHAR(32000);

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
