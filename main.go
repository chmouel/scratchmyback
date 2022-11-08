package main

import (
	"log"
	"strconv"
)

func main() {
  s := "0"
  _, err := strconv.Atoi(s)
  if err != nil  {
    log.Fatal(err)
  }
  _, err = strconv.Atoi(s)
}
