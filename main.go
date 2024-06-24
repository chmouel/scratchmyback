package main

import (
	"fmt"

	oGitHub "github.com/google/go-github/v60/github"
	tektonv1 "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {
	oGitHub.NewClient(nil)
	pr := tektonv1.PipelineRun{
		ObjectMeta: metav1.ObjectMeta{Name: "hello"},
	}
	fmt.Printf("pr: %v\n", pr)
}
