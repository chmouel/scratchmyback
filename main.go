package main

import (
	"fmt"

	tektonv1 "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {
	pr := tektonv1.PipelineRun{
		ObjectMeta: metav1.ObjectMeta{Name: "hello"},
	}
	fmt.Printf("pr: %v\n", pr)
}
