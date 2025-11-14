package main

import (
    "bytes"
    "fmt"
    "io/ioutil"
    "net/http"
)

func main() {
    const apiKey = "K82298008188957" // Free tier key
    url := "https://api.ocr.space/parse/image"

    payload := &bytes.Buffer{}
    payload.WriteString("url=https://example.com/lesson.jpg&language=eng")

    req, _ := http.NewRequest("POST", url, payload)
    req.Header.Add("apikey", apiKey)
    req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

    client := &http.Client{}
    resp, _ := client.Do(req)
    defer resp.Body.Close()
    body, _ := ioutil.ReadAll(resp.Body)
    fmt.Println(string(body))
}
