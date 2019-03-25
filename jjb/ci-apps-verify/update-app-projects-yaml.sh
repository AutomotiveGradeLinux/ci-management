#!/bin/bash
agl-gerrit-lsprojects-apps  | sed -e "s'apps/'- 'g"  > app-projects.yaml.inc
