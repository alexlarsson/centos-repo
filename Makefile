all: platform sdk

PROXY=
VERSION=7
REVISION=1
ARCH=x86_64

repo/config:
	ostree init --repo=repo --mode=bare-user

exportrepo/config:
	ostree init --repo=exportrepo --mode=archive-z2

%.repo: %.repo.in
	sed -e "s|\@CWD\@|`pwd`|"  $< > $@

# base rpms
centos-runtime: rpms/RPMS/noarch/centos-runtime-$(VERSION)-$(REVISION).el7.noarch.rpm

rpms/RPMS/noarch/centos-runtime-$(VERSION)-$(REVISION).el7.noarch.rpm: specfiles/centos-runtime.spec rpmbuild.sh
	./rpmbuild.sh --define "ver $(VERSION)" --define "rev $(REVISION)" --define "dist .el7" -ba specfiles/centos-runtime.spec

centos-sdk: rpms/RPMS/noarch/centos-sdk-$(VERSION)-$(REVISION).el7.noarch.rpm

rpms/RPMS/noarch/centos-sdk-$(VERSION)-$(REVISION).el7.noarch.rpm: specfiles/centos-sdk.spec rpmbuild.sh
	./rpmbuild.sh --define "ver $(VERSION)" --define "rev $(REVISION)" --define "dist .el7" -ba specfiles/centos-sdk.spec

# local yum repo

rpms/RPMS/noarch/repodata/repomd.xml: rpms/RPMS/noarch/centos-runtime-$(VERSION)-$(REVISION).el7.noarch.rpm rpms/RPMS/noarch/centos-sdk-$(VERSION)-$(REVISION).el7.noarch.rpm
	createrepo rpms/RPMS/noarch

repo/refs/heads/base/org.centos.Platform/$(ARCH)/$(VERSION): repo/config CentOS-Base.repo local.repo centos-runtime.json treecompose-post.sh group passwd rpms/RPMS/noarch/repodata/repomd.xml
	sudo rpm-ostree compose tree --force-nocache $(PROXY) --repo=repo centos-runtime.json
	sudo chown -R `whoami` repo

repo/refs/heads/base/org.centos.Sdk/$(ARCH)/$(VERSION): repo/config CentOS-Base.repo local.repo centos-sdk.json centos-runtime.json treecompose-post.sh group passwd rpms/RPMS/noarch/repodata/repomd.xml
	sudo rpm-ostree compose tree --force-nocache $(PROXY) --repo=repo centos-sdk.json
	sudo chown -R `whoami` repo

repo/refs/heads/runtime/org.centos.Platform/$(ARCH)/$(VERSION): repo/refs/heads/base/org.centos.Platform/$(ARCH)/$(VERSION) metadata.platform
	./commit-subtree.sh base/org.centos.Platform/$(ARCH)/$(VERSION) runtime/org.centos.Platform/$(ARCH)/$(VERSION) metadata.platform /usr files

repo/refs/heads/runtime/org.centos.Platform.Var/$(ARCH)/$(VERSION): repo/refs/heads/base/org.centos.Platform/$(ARCH)/$(VERSION) metadata.platform
	./commit-subtree.sh base/org.centos.Platform/$(ARCH)/$(VERSION) runtime/org.centos.Platform.Var/$(ARCH)/$(VERSION) metadata.platform /var files  /usr/share/rpm files/lib/rpm

repo/refs/heads/runtime/org.centos.Sdk/$(ARCH)/$(VERSION): repo/refs/heads/base/org.centos.Sdk/$(ARCH)/$(VERSION) metadata.sdk
	./commit-subtree.sh base/org.centos.Sdk/$(ARCH)/$(VERSION) runtime/org.centos.Sdk/$(ARCH)/$(VERSION) metadata.sdk /usr files

repo/refs/heads/runtime/org.centos.Sdk.Var/$(ARCH)/$(VERSION): repo/refs/heads/base/org.centos.Sdk/$(ARCH)/$(VERSION) metadata.sdk
	./commit-subtree.sh base/org.centos.Sdk/$(ARCH)/$(VERSION) runtime/org.centos.Sdk.Var/$(ARCH)/$(VERSION) metadata.sdk /var files /usr/share/rpm files/lib/rpm

exportrepo/refs/heads/runtime/org.centos.Platform/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.centos.Platform/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.centos.Platform/$(ARCH)/$(VERSION)

exportrepo/refs/heads/runtime/org.centos.Platform.Var/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.centos.Platform.Var/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.centos.Platform.Var/$(ARCH)/$(VERSION)

exportrepo/refs/heads/runtime/org.centos.Sdk/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.centos.Sdk/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.centos.Sdk/$(ARCH)/$(VERSION)

exportrepo/refs/heads/runtime/org.centos.Sdk.Var/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.centos.Sdk.Var/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.centos.Sdk.Var/$(ARCH)/$(VERSION)

platform: exportrepo/refs/heads/runtime/org.centos.Platform/$(ARCH)/$(VERSION) exportrepo/refs/heads/runtime/org.centos.Platform.Var/$(ARCH)/$(VERSION)

sdk: exportrepo/refs/heads/runtime/org.centos.Sdk/$(ARCH)/$(VERSION) exportrepo/refs/heads/runtime/org.centos.Sdk.Var/$(ARCH)/$(VERSION)

clean:
	rm -rf repo exportrepo rpms CentOS-Base.repo local.repo
