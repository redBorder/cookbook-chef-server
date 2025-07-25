Name: cookbook-chef-server
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: Chef server cookbook to install and configure it in redborder environments

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-chef-server
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/chef-server
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/chef-server/
chmod -R 0755 %{buildroot}/var/chef/cookbooks/chef-server
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/chef-server/README.md

%pre
if [ -d /var/chef/cookbooks/chef-server ]; then
    rm -rf /var/chef/cookbooks/chef-server
fi

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload chef-server'
  ;;
esac

%postun
# Deletes directory when uninstall the package
if [ "$1" = 0 ] && [ -d /var/chef/cookbooks/chef-server ]; then
  rm -rf /var/chef/cookbooks/chef-server
fi

%files
%defattr(0644,root,root)
%attr(0755,root,root)
/var/chef/cookbooks/chef-server
%defattr(0644,root,root)
/var/chef/cookbooks/chef-server/README.md

%doc

%changelog
* Thu Oct 10 2024 Miguel Negrón <manegron@redborder.com>
- Add pre and postun

* Fri Dec 01 2023 Miguel Negrón <manegron@redborder.com>
- Add sync ip suppport

* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com>
- change register to consul

* Tue Oct 18 2016 Alberto Rodríguez <arodriguez@redborder.com>
- first spec version
