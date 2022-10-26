package armo_builtins

# Check if --client-cert-auth is set to true
deny[msga] {
	obj = input[_]
	is_etcd_pod(obj)
	result = invalid_flag(obj.spec.containers[0].command)

	msga := {
		"alertMessage": "Etcd server is not requiring a valid client certificate",
		"alertScore": 8,
		"packagename": "armo_builtins",
		"failedPaths": result.failed_paths,
		"fixPaths": result.fix_paths,
		"alertObject": {"k8sApiObjects": [obj]},
	}
}

is_etcd_pod(obj) {
	obj.apiVersion == "v1"
	obj.kind == "Pod"
	count(obj.spec.containers) == 1
	endswith(split(obj.spec.containers[0].command[0], " ")[0], "etcd")
}

# Assume flag set only once
invalid_flag(cmd) = result {
	full_cmd = concat(" ", cmd)
	not contains(full_cmd, "--client-cert-auth")
	result := {
		"failed_paths": [],
		"fix_paths": [{
			"path": sprintf("spec.containers[0].command[%d]", [count(cmd)]),
			"value": "--client-cert-auth=true",
		}],
	}
}

invalid_flag(cmd) = result {
	contains(cmd[i], "--client-cert-auth=false")
	fixed = replace(cmd[i], "--client-cert-auth=false", "--client-cert-auth=true")
	path := sprintf("spec.containers[0].command[%d]", [i])
	result = {
		"failed_paths": [path],
		"fix_paths": [{"path": path, "value": fixed}],
	}
}