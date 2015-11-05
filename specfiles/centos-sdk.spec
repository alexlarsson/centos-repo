Name:           centos-sdk
Version:        %{ver}
Release:        %{rev}%{?dist}
Summary:        An xdg-app sdk runtime based on centos
BuildArch:      noarch

License:        GPL

Requires:       centos-runtime
Requires:       valgrind
Requires:       strace
Requires:       gdb
Requires:       cpio
Requires:       rpm-build
Requires:       yum

%description
An xdg-app sdk for the fedora runtime

%prep


%build


%install
rm -rf $RPM_BUILD_ROOT


%files

%changelog
* Wed Jun  3 2015 Alexander Larsson <alexl@redhat.com>
- Initial version
