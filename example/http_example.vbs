Dim influxURL, org, bucket, token
' InfluxDB 서버 정보 및 인증 토큰
influxURL = "http://121.189.56.245:8086/api/v2/write"
org = "bigdatalabs"
bucket = "mybucket"
token = "Cj3BI-zELUdOXUNqsEL_4BS7S1YQfivmbmJRx2fNpOwSFEwI6DZYZ3yU3rMxGp39y1wa-F0kMWmyDtAPDd9i6g=="

' MSXML2.ServerXMLHTTP 객체 생성
Dim http
On Error Resume Next
Set http = CreateObject("MSXML2.ServerXMLHTTP")
If Err.Number <> 0 Then
    MsgBox "MSXML 객체 초기화 실패: " & Err.Description & " (Error Code: " & Err.Number & ")"
    Err.Clear
    'WScript.Quit
End If
On Error GoTo 0

' 연결 URL 구성
Dim connStr
connStr = influxURL & "?org=" & org & "&bucket=" & bucket

' 배열 선언 및 데이터 초기화
Dim devices(2, 13)
' FEEDER 데이터
devices(0, 0) = "FEEDER"
devices(0, 1) = "RUNNING"
devices(0, 2) = GetTagVal("LINE.SPEED_SV")
devices(0, 3) = GetTagVal("LINE.SPEED_PV")
devices(0, 4) = 0
devices(0, 5) = 0
devices(0, 6) = GetTagVal("LINE.FEED_VOLT_PV")
devices(0, 7) = GetTagVal("LINE.FEED_CURRENT_PV")
devices(0, 8) = GetTagVal("LINE.FEED_POWER_PV")
devices(0, 9) = GetTagVal("LINE.FEED_TEMP_PV")
devices(0, 10) = GetTagVal("LINE.FEED_RPM_PV")
devices(0, 11) = GetTagVal("LINE.FEED_TORQUE_PV")
devices(0, 12) = GetTagVal("LINE.FEED_HZ_PV")
devices(0, 13) = 0

' UNWINDER 데이터
devices(1, 0) = "UNWINDER"
devices(1, 1) = "RUNNING"
devices(1, 2) = GetTagVal("LINE.SPEED_SV")
devices(1, 3) = GetTagVal("LINE.SPEED_PV")
devices(1, 4) = GetTagVal("LINE.UW_TENSION_SV")
devices(1, 5) = GetTagVal("LINE.UW_TENSION_PV")
devices(1, 6) = GetTagVal("LINE.UW_VOLT_PV")
devices(1, 7) = GetTagVal("LINE.UW_CURRENT_PV")
devices(1, 8) = GetTagVal("LINE.UW_POWER_PV")
devices(1, 9) = GetTagVal("LINE.UW_TEMP_PV")
devices(1, 10) = GetTagVal("LINE.UW_RPM_PV")
devices(1, 11) = GetTagVal("LINE.UW_TORQUE_PV")
devices(1, 12) = GetTagVal("LINE.UW_HZ_PV")
devices(1, 13) = GetTagVal("LINE.UW_DANCER_POS_PV")

' REWINDER 데이터
devices(2, 0) = "REWINDER"
devices(2, 1) = "RUNNING"
devices(2, 2) = GetTagVal("LINE.SPEED_SV")
devices(2, 3) = GetTagVal("LINE.SPEED_PV")
devices(2, 4) = GetTagVal("LINE.RW_TENSION_SV")
devices(2, 5) = GetTagVal("LINE.RW_TENSION_PV")
devices(2, 6) = GetTagVal("LINE.RW_VOLT_PV")
devices(2, 7) = GetTagVal("LINE.RW_CURRENT_PV")
devices(2, 8) = GetTagVal("LINE.RW_POWER_PV")
devices(2, 9) = GetTagVal("LINE.RW_TEMP_PV")
devices(2, 10) = GetTagVal("LINE.RW_RPM_PV")
devices(2, 11) = GetTagVal("LINE.RW_TORQUE_PV")
devices(2, 12) = GetTagVal("LINE.RW_HZ_PV")
devices(2, 13) = GetTagVal("LINE.RW_DANCER_POS_PV")

' 데이터 전송 루프
Dim i, measurement, tags, fields, lineProtocol
For i = 0 To UBound(devices, 1)
    ' InfluxDB Line Protocol 구성
    measurement = "machine_data"
    tags = "device_name=" & devices(i, 0) & ",status=" & devices(i, 1)
    fields = "speed_sv=" & devices(i, 2) & ",speed_pv=" & devices(i, 3) & _
             ",tension_sv=" & devices(i, 4) & ",tension_pv=" & devices(i, 5) & _
             ",volt=" & devices(i, 6) & ",current=" & devices(i, 7) & _
             ",power=" & devices(i, 8) & ",temp=" & devices(i, 9) & _
             ",rpm=" & devices(i, 10) & ",torque=" & devices(i, 11) & _
          ",Hz=" & devices(i, 12) & ",dancer_pos=" & devices(i, 13)
    lineProtocol = measurement & "," & tags & " " & fields

    ' 디버깅 메시지 출력
    'MsgBox "Sending data: " & lineProtocol

    ' HTTP 요청
    On Error Resume Next
    http.Open "POST", connStr, False
    If Err.Number <> 0 Then
        MsgBox "HTTP Open 실패: " & Err.Description & " (Error Code: " & Err.Number & ")"
        Err.Clear
        Exit For
    End If
    On Error GoTo 0

    http.setRequestHeader "Authorization", "Token " & token
    http.setRequestHeader "Content-Type", "text/plain; charset=utf-8"

    On Error Resume Next
    http.Send lineProtocol
    If Err.Number <> 0 Then
        MsgBox "HTTP Send 실패: " & Err.Description & " (Error Code: " & Err.Number & ")"
        Err.Clear
        Exit For
    End If
    On Error GoTo 0

    ' 응답 상태 확인
    If http.Status <> 204 Then
        MsgBox "Failed to insert data for " & devices(i, 0) & ". HTTP Status: " & http.Status & " - " & http.responseText
    Else
        'MsgBox "Data for " & devices(i, 0) & " inserted successfully!"
    End If
Next

' MSXML 객체 해제
Set http = Nothing
