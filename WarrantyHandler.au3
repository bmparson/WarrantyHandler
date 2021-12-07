#include<MyWinHTTP.au3>
#include<date.au3>
#include<array.au3>

Func DellWarranty(const $serial)
; Open needed handles
   $hOpen = _WinHttpOpen()
   $hConnect = _WinHttpConnect($hOpen, "apigtwb2c.us.dell.com")
; Specify and send the token reguest using provided credentials from Dell
   $hSSLRequest = _WinHttpSimpleSendSSLRequest($hConnect, "POST", "auth/oauth/v2/token", Default,"grant_type=client_credentials","Authorization: Basic <Your Base64 Dell API Key Here>"& @CRLF& "Content-Type: application/x-www-form-urlencoded" & @CRLF ,0)
; wait for Response
   $response =_WinHttpSimpleReadData($hsslRequest)
; Close initial request
   _WinHttpCloseHandle($hSSLRequest)
; Grab Bearer Token generated by request
   $token=stringregexp($response,'"access_token":"(.*?)",',1)
; Specify and send the warranty request with provided serial number
   $hSSLRequest = _WinHttpSimpleSendSSLRequest($hConnect, "GET", "PROD/sbil/eapi/v5/asset-entitlements?servicetags=" & $serial, Default,Default,"Authorization: Bearer " & $token[0],0)
; wait for response
   $response =_WinHttpSimpleReadData($hsslRequest)
   $purchased=stringregexp($response,'"startDate":"(.{0,10})T\d*?:\d*?:\d*?Z","endDate":"\d*?-\d*?-\d*?T\d*?:\d*?:\d*?\.\d*?Z","entitlementType":"(?=INITIAL)',1)
   $purchaseddate=stringregexpreplace($purchased[0], "(\d{4})-(\d{2})-(\d{2})","$1/$2/$3" )
   $warrantyends=stringregexp($response,'"endDate":"(\d*?-\d*?-\d*?)T',3)
   $warrantydays = GetWarrantyExpiration($warrantyends)
   $return=$purchaseddate &","&$warrantydays
   ; Clean
   _WinHttpCloseHandle($hSSLRequest)
   _WinHttpCloseHandle($hConnect)
   _WinHttpCloseHandle($hOpen)
   Return $return
endfunc

Func LenovoWarranty(const $Serial)
   $hOpen = _WinHttpOpen()
   $hConnect = _WinHttpConnect($hOpen, "supportapi.lenovo.com")
   $hSSLRequest = _WinHttpSimpleSendSSLRequest($hConnect, "POST", "v2.5/warranty", Default,"Serial="&$Serial ,"ClientId: <Your ClientID Here"& @CRLF& "Content-Type: application/x-www-form-urlencoded" & @CRLF ,0)
   $response =_WinHttpSimpleReadData($hsslRequest)
   $purchased=stringregexp($response,'"Purchased":"(.*?)T',1)
   $warrantyends=stringregexp($response,'"End":"(.*?)T',3)
   $purchaseddate=stringregexpreplace($purchased[0], "(\d{4})-(\d{2})-(\d{2})","$1/$2/$3" )
   $warrantydays = GetWarrantyExpiration($warrantyends)
   $return=$purchaseddate &","&$warrantydays
   ; Clean
   _WinHttpCloseHandle($hSSLRequest)
   _WinHttpCloseHandle($hConnect)
   _WinHttpCloseHandle($hOpen)
   Return $return
EndFunc

Func GetFormattedNowDate()
   $now = stringregexpreplace(_nowdate(), "(\d{1}|\d{2})\/(\d{1}|\d{2})\/(\d{4})", "$3/$1/$2")
  Return $now
EndFunc

Func GetWarrantyExpiration($warrantyends)
   $now=GetFormattedNowDate()
   $j=ubound($warrantyends)
   Local $daysleft[$j]
	  for $i = 0 to $j-1 step 1
		 $warrantyends[$i] = stringregexpreplace($warrantyends[$i], "(\d{4})-(\d{2})-(\d{2})","$1/$2/$3" )
		 $daysleft[$i]=_datediff("D",$now,$warrantyends[$i])
	  Next
	  $k=_arraymaxindex($daysleft)
	  if $daysleft[$k] > 0 Then
		 $warrantydays = $daysleft[$k]
	  Else
		 $warrantydays = "Expired"
	  EndIf

   Return $warrantydays
EndFunc