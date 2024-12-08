Dim influxURL, org, bucket, token
' InfluxDB 서버 정보 및 인증 토큰
influxURL = "https://bigdatalab.cloud249.com:8086/api/v2/write"
org = "bigdatalabs"
bucket = "jmetertester"
token = "Cj3BI-zELUdOXUNqsEL_4BS7S1YQfivmbmJRx2fNpOwSFEwI6DZYZ3yU3rMxGp39y1wa-F0kMWmyDtAPDd9i6g=="

' MSXML2.ServerXMLHTTP.6.0 객체 생성
Dim http
Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")

' 연결 URL 구성
Dim connStr
connStr = influxURL & "?org=" & org & "&bucket=" & bucket

' 데이터 배열 초기화
Dim devices(2, 13)
devices(0, 0) = "FEEDER": devices(0, 1) = "RUNNING": devices(0, 2) = 100
devices(0, 3) = 95: devices(0, 4) = 0: devices(0, 5) = 0
devices(0, 6) = 220: devices(0, 7) = 10: devices(0, 8) = 2000
devices(0, 9) = 50: devices(0, 10) = 3000: devices(0, 11) = 20
devices(0, 12) = 60: devices(0, 13) = 0

devices(1, 0) = "UNWINDER": devices(1, 1) = "RUNNING": devices(1, 2) = 100
devices(1, 3) = 95: devices(1, 4) = 500: devices(1, 5) = 480
devices(1, 6) = 220: devices(1, 7) = 10: devices(1, 8) = 2000
devices(1, 9) = 50: devices(1, 10) = 3000: devices(1, 11) = 20
devices(1, 12) = 60: devices(1, 13) = 5

devices(2, 0) = "REWINDER": devices(2, 1) = "RUNNING": devices(2, 2) = 100
devices(2, 3) = 95: devices(2, 4) = 500: devices(2, 5) = 480
devices(2, 6) = 220: devices(2, 7) = 10: devices(2, 8) = 2000
devices(2, 9) = 50: devices(2, 10) = 3000: devices(2, 11) = 20
devices(2, 12) = 60: devices(2, 13) = 5

' 배치 크기 설정
Dim batchSize, batchData, counter
batchSize = 500 ' 원하는 배치 크기 설정
batchData = ""
counter = 0

For i = 0 To UBound(devices, 1)
    Dim measurement, tags, fields, lineProtocol
    measurement = "sensor_data"
    tags = "device_name=" & devices(i, 0) & ",status=" & devices(i, 1)
    fields = "speed_sv=" & CDbl(devices(i, 2)) & _
             ",speed_pv=" & CDbl(devices(i, 3)) & _
             ",tension_sv=" & CDbl(devices(i, 4)) & _
             ",tension_pv=" & CDbl(devices(i, 5)) & _
             ",volt=" & CDbl(devices(i, 6)) & _
             ",current=" & CDbl(devices(i, 7)) & _
             ",power=" & CDbl(devices(i, 8)) & _
             ",temp=" & CDbl(devices(i, 9)) & _
             ",rpm=" & CDbl(devices(i, 10)) & _
             ",torque=" & CDbl(devices(i, 11)) & _
             ",Hz=" & CDbl(devices(i, 12)) & _
             ",dancer_pos=" & CDbl(devices(i, 13))
    lineProtocol = measurement & "," & tags & " " & fields

    ' 줄바꿈 문자 제거
    lineProtocol = Replace(lineProtocol, vbCr, "")
    lineProtocol = Replace(lineProtocol, vbLf, "")

    ' 디버깅: Line Protocol 출력
    WScript.Echo "Line Protocol: " & lineProtocol

    ' 배치 데이터에 추가
    batchData = batchData & lineProtocol & vbLf
    counter = counter + 1

    ' 배치 크기에 도달하면 데이터 전송
    If counter >= batchSize Then
        batchData = Replace(batchData, vbCr, "")
        batchData = Replace(batchData, vbLf & vbLf, vbLf) ' 불필요한 빈 줄 제거

        ' 디버깅: 현재 배치 데이터 출력
        WScript.Echo "Batch Data to send: " & batchData

        ' HTTP 요청
        http.Open "POST", connStr, False
        http.setRequestHeader "Authorization", "Token " & token
        http.setRequestHeader "Content-Type", "text/plain; charset=utf-8"
        http.Send batchData

        ' HTTP 응답 상태 확인
        WScript.Echo "HTTP Status: " & http.Status & " - " & http.responseText

        ' 배치 데이터 초기화
        batchData = ""
        counter = 0
    End If
Next

' 남은 데이터 전송
If counter > 0 Then
    batchData = Replace(batchData, vbCr, "")
    batchData = Replace(batchData, vbLf & vbLf, vbLf)

    ' 디버깅: 남은 데이터 출력
    WScript.Echo "Final Batch Data: " & batchData

    ' HTTP 요청
    http.Open "POST", connStr, False
    http.setRequestHeader "Authorization", "Token " & token
    http.setRequestHeader "Content-Type", "text/plain; charset=utf-8"
    http.Send batchData

    ' HTTP 응답 상태 확인
    WScript.Echo "HTTP Status: " & http.Status & " - " & http.responseText
End If
