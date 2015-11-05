#!/bin/sh
set -e
rpmbuild --define "_topdir `pwd`/rpms" --define "_srcrpmdir `pwd`/rpms/SRPMS" --define "_sourcedir `pwd`/specfiles/SOURCES" "$@"
