#!/usr/bin/env python

import os
import re
import json

_DEFAULT_OUTPUT = "compile_commands.json"

root = os.getcwd()
_FILENAME_PATTERN = r'.*\.o\.cmd$'
_LINE_PATTERN = r'.*\.o\.cmd := (.*\.o)$'
cmdfile = re.compile(_FILENAME_PATTERN)
cmdline = re.compile(_LINE_PATTERN)

def json_entry(filepath, command):
	path = os.path.dirname(filepath)
	filename = os.path.basename(filepath).replace(".o.cmd", ".c")

	return {
		"directory": path,
		"command": command,
		"file": filename,
	}

def main():
	compile_json = []

	for path, dirs, filenames in os.walk(root):
		for filename in filenames:
			if not cmdfile.match(filename):
				continue

			filepath = os.path.join(root, path, filename)

			with open(filepath, 'rt') as f:
				result = cmdline.match(f.readline())
				entry = json_entry(filepath, result.group(1))
				compile_json.append(entry)

	with open(_DEFAULT_OUTPUT, 'wt') as f:
		json.dump(compile_json, f, indent=2, sort_keys=True)

if __name__ == '__main__':
	main()
