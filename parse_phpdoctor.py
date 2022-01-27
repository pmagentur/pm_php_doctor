#!/usr/bin/env python3
import sys
import requests
import re
max_number_per_request = 50 # this is the max number of anotation per requset

# Annotation should have this structure
# Annotation = {                
#   path: string;
#   start_line: number;
#   end_line: number;
#   start_column?: number; #optional
#   end_column?: number; #optional
#   annotation_level: "notice" | "warning" | "failure";
#   message: string;
#   title?: string; #optional
#   raw_details?: string; #optional
# }


def get_all_violations(txt_file: str) -> dict:
    github_prefix = "/github/workspace/"
    violations = [] # for max_number_per_request annotations  
    all_violations = [] # array of violations
    # init regex
    filename_line_regex = re.compile('^[/:w+].+.php \([0-9]+ errors\)$')
    file_path_regex = re.compile('^[/:w+].+.php')
    all_error_regex = re.compile('[A-z]+: \[[0-9]+\].*$')
    error_regex = re.compile('^[A-z]+')
    error_line_regex = re.compile('^[A-z]+: \[[0-9]+\]:')

    # Opening txt
    error_file = open(txt_file, 'r')
    Lines = error_file.readlines()
    annotation_path=""
    for line in Lines:
        filename_line = filename_line_regex.match(line)
        error = all_error_regex.match(line)
        if (filename_line == None) & (error == None):
            continue
        elif filename_line != None:
            annotation_path = file_path_regex.match(line).group(0).replace(github_prefix,"")
        elif error != None:
            annotation_line = error_line_regex.match(line).group(0).split("[")[1].split("]")[0]
            annotation_level_value = error_regex.match(line).group(0)
            annotation_level = "failure" if annotation_level_value == "Error" else "warning"
            annotation_message = line.replace(annotation_level_value+": "+"["+annotation_line+"]"+":","")
            violation = {"path":annotation_path, "start_line":int(annotation_line),"end_line":int(annotation_line),"annotation_level":annotation_level, "message":annotation_message}
            if len(violations) < max_number_per_request:
                violations.append(violation)
            else:
                all_violations.append(violations)
                violations = []
    all_violations.append(violations)
    return all_violations

def update_pr(owner, repo_name, head_sha, file):
    URL = "https://pm-code-check.pm-projects.de/pm-checks/annotations/create"
    params = {"owner": owner, "repo_name": repo_name, "head_sha": head_sha, "check_name": "Phpdoctor check"}
    head = {"Content-Type'": "application/json"}
    all_violations = get_all_violations(file)
    for violations in all_violations:
        response = requests.post(URL, json=violations, params=params, headers=head)
        # TODO handle response if error

def main():
    owner = sys.argv[1]
    repo_name = sys.argv[2]
    head_sha = sys.argv[3]
    file= sys.argv[4]
    update_pr(owner, repo_name, head_sha,file)

main()