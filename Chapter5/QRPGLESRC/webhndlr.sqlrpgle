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

  If %upper(pMethod) = 'GET ';

    // If Request Data is blank return null
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
        pResponseData = '{ "error": "Invalid JSON format" }';
        Return;
      EndIf;
    EndIf;

    Select;
      When vApp = 'PRODUCT' and vAction = 'GETPRODUCTLIST';
        // Call the procedure to get the Product List in JSON format
        vJsonString = GetProductList();
        pResponseData = vJsonString;
      Other;
        pResponseData = '{ "error": "Unknown action" }';
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
