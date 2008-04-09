set :application, "tools.six3d.org"
set :repository,  "http://svn.six3d.org/trunk/tools"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"
set :deploy_to, "/home/bennybula/Sites/#{application}"

set :scm_username, "bob"
set :scm_password, "lalala"
set :use_sudo, false

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "bennybula@tools.six3d.org"
role :web, "bennybula@tools.six3d.org"