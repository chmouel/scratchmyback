package main

import (
	"fmt"
	"log"
	"os"
)

func main() {
	// this wil fail
	f, err := os.Create("/etc/passwrd")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%+v\n", f)
}
