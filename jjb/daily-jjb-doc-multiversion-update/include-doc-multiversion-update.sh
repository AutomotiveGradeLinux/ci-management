#!/bin/bash
set -e

# make sure 'node' is in path (debian calls it nodejs)
mkdir -p bin
ln -sf /usr/bin/nodejs bin/node
export PATH=$PATH:`pwd`/bin

[[ -z "$WORKSPACE" ]] && WORKSPACE=$(pwd -P)
echo "Using workspace $WORKSPACE"
TMPDIR=${TMPDIR:-$WORKSPACE/docs-webtemplate}
HTDOCS=${HTDOCS:-$WORKSPACE/htdocs}
mkdir -p $HTDOCS

trap "rm -rf $WORKSPACE/setupdocs.sh $TMPDIR" STOP INT QUIT EXIT

# setupdocs is already imported from automotive-grade-linux/docs-webtemplate
#wget -O $WORKSPACE/setupdocs.sh https://raw.githubusercontent.com/automotive-grade-linux/docs-webtemplate/master/setupdocs.sh
wget -O $WORKSPACE/setupdocs.sh https://git.automotivelinux.org/ci-management/plain/jjb/daily-jjb-doc-multiversion-update/setupdocs.sh

chmod +x $WORKSPACE/setupdocs.sh

function gensite() {
	local branch=${1:-master}
	local tmp=$TMPDIR/$branch

	mkdir -p $tmp

	$WORKSPACE/setupdocs.sh -w master -d $tmp

	pushd $tmp

		tocsdir="tocs_$branch"
		# exception for master branch to keep aligned with legacy tocs_agl
		[[ "$branch" == "master" ]] && tocsdir="tocs"

		sed -i "s|^baseurl:.*$|baseurl: \"/$branch\"|g" conf/_dev.yml
		sed -i "s|^docsurl:.*$|docsurl: \"/$branch/docs\"|g" conf/_config.yml
		cat <<-EOF >>conf/AppDefaults.js
			config.TOCS_DIR="$PWD/content/$tocsdir";
			config.AGL_GERRIT_BRANCH="$branch";
			config.AGL_GITHUB_BRANCH="$branch";
		EOF

        navbarColor="#222"
        typeDocStr="master branch"
		if [ "$branch" == "flounder" ]; then
            navbarColor="darkslategray"
            typeDocStr="Flounder release"
        fi

	git apply <<EOF
diff --git a/site/_includes/header.html b/site/_includes/header.html
index 6828472..26035b0 100644
--- a/site/_includes/header.html
+++ b/site/_includes/header.html
@@ -1,9 +1,9 @@
 <header>
     <a class="scroll-point pt-top" name="top"></a>
-    <nav class="navbar navbar-inverse navbar-fixed-top">
+    <nav class="navbar navbar-inverse navbar-fixed-top" style="background-color: ${navbarColor};">
         <div class="container-fluid">
             <div class="navbar-header">
-                <a class="navbar-brand" href="{{ site.baseurl }}/"><img id="logo_top" src="{{ site.baseurl }}{{ site.logo.navbar }}"/></a>
+                <a class="navbar-brand" href="/"><img id="logo_top" src="{{ site.baseurl }}{{ site.logo.navbar }}"/></a>
                 <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                     <span class="sr-only">Toggle navigation</span>
                     <span class="icon-bar"></span>
@@ -35,6 +35,13 @@
                         </li>
 					</ul>
 				</div>
+			    <div class="nav_bar_center">
+                    <ul class="nav navbar-nav" style="margin-left: 5%;">
+                        <li>
+                        <a style="color:red;"><b>${typeDocStr} documentation</b></a>
+                        </li>
+                    </ul>
+                </div>
                 <div class="nav_bar_right">
                     <ul class="nav navbar-nav">
 {% comment %} <!-- disabled because posts are not updated - see SPEC-2029 -->
EOF

        make build
        rsync -Pav --delete build-dev/ $HTDOCS/$branch/

    popd
}

gensite master
gensite flounder

# front page
echo "Generating front page in $HTDOCS/index.html"
cat <<EOF >$HTDOCS/index.html
<html lang="en">
<head>
   <meta charset="utf-8">
   <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
   <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
   <meta name="format-detection" content="telephone=no">
   <meta name="viewport" content="user-scalable=no, initial-scale=1, maximum-scale=1, minimum-scale=1, width=device-width">
   <meta name="description" content=" ">
   <title>AGL Documentation Site</title>
   <link rel="SHORTCUT ICON" href="/master/favicon.ico">
   <link rel="canonical" href="http://docs.automotivelinux.org/">
   <!-- CSS -->
   <link rel="stylesheet" type="text/css" href="/master/static/styles/main.css">
   <link rel="stylesheet" type="text/css" href="/master/static/styles/syntax.css">
   <!-- Fonts -->
   <!-- For attribution information, see www/attributions.html -->
   <link href="https://fonts.googleapis.com/css?family=Raleway:700,400,300,700italic,400italic,300italic" rel="stylesheet"
      type="text/css">
   <!-- JS -->
   <script async="" src="//www.google-analytics.com/analytics.js"></script>
   <script defer="" type="text/javascript" src="/master/static/js/lib/jquery-2.1.1.min.js"></script>
   <script defer="" type="text/javascript" src="/master/static/js/lib/bootstrap.min.js"></script>
   <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
       (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
       m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
       })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
       ga('create', '', 'auto');
       ga('send', 'pageview');
    </script>
</head>

<style>
#hero {
    display: flex;
}
#hero #hero_section {
    margin: auto;
    font-size: 25px;
}
#hero #hero_section > div {
    display: flex;
    justify-content: center;
}
</style>

<body>
   <header>
      <a class="scroll-point pt-top" name="top"></a>
      <nav class="navbar navbar-inverse navbar-fixed-top">
         <div class="container-fluid">
            <div class="navbar-header">
               <a class="navbar-brand" href="/"><img id="logo_top" src="/master/static/img/branding/agl_title_793x211.png" /></a>
               <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar"
                  aria-expanded="false" aria-controls="navbar">
                  <span class="sr-only">Toggle navigation</span>
                  <span class="icon-bar"></span>
                  <span class="icon-bar"></span>
                  <span class="icon-bar"></span>
               </button>
            </div>
         </div>
         <!--/.navbar-collapse -->
      </nav>
      <div id="_fixed_navbar_spacer" style="padding-top:50px"></div>
   </header>
   <div id="hero">
      <div id="hero_section">
         <div>
            <p>Welcome to AGL documentation website</p>
         </div>
         <div>
            <p><em>Please select the documentation version :</em></p>
         </div>

         <div class="hero_buttons">
            <a href="/master" class="col-xs-12 col-sm-5 btn btn-lg btn-primary" style="margin: auto;">Master (Development)</a>
            <a href="/flounder" class="col-xs-12 col-sm-5 btn btn-lg btn-primary">Flounder (AGL 6.x)</a>
         </div>
      </div>
   </div>
   <div class="blue-divider"></div>
   <footer>
      <div class="container">
         <div class="row">
            <div class="col-sm-9">
               <h1>More Resources</h1>
               <div class="row">
                  <div class="col-sm-4">
                     <h2>General</h2>
                     <ul class="nav">
                        <li>
                           <a target="_blank" href="https://www.automotivelinux.org/">AGL Developer Community</a>
                        </li>
                        <li>
                           <a href="https://www.automotivelinux.org/software/download/">Download Distribution</a>
                        </li>
                        <li>
                           <a href="https://gerrit.automotivelinux.org/gerrit/#/admin/projects/">Source Code on Git</a>
                        </li>
                        <li>
                           <a target="_blank" href="http://lists.linuxfoundation.org/mailman/listinfo/automotive-discussions">Mailing List</a>
                        </li>
                     </ul>
                  </div>
                  <div class="col-sm-4">
                     <h2>Development</h2>
                     <ul class="nav">
                        <li><a target="_blank" href="https://wiki.automotivelinux.org/agl-distro/source-code">Source
                              Code</a></li>
                        <li><a target="_blank" href="https://jira.automotivelinux.org/browse/SPEC/?selectedTab=com.atlassian.jira.jira-projects-plugin:summary-panel">Issue
                              Tracker</a></li>
                        <li><a target="_blank" href="https://wiki.automotivelinux.org/">Wiki</a></li>
                        <li><a href="https://www.automotivelinux.org/contact">Contact</a></li>
                     </ul>
                  </div>
                  <div class="col-sm-4">
                     <h2>Automotive Grade Linux @ Linux Foundation</h2>
                     <ul class="nav">
                        <li>
                           <a target="_blank" href="https://www.automotivelinux.org/">About AGL</a>
                        </li>
                        <li>
                           <a target="_blank" href="http://www.linuxfoundation.org/">About Linux Foundation</a>
                        </li>
                        <li>
                           <a target="_blank" href="https://wiki.automotivelinux.org/start/getting-started">Join AGL
                              community</a>
                        </li>
                        <li>
                           <a target="_blank" href="https://www.automotivelinux.org/about/members">Members</a>
                        </li>
                     </ul>
                  </div>
               </div>
            </div>
            <div class="col-sm-3">
               <h1>Contribute</h1>
               <p style="padding-top:20px"><strong>Help AGL move forward!</strong></p>
               <p>Report bugs, improve the docs, or contribute to the code.</p>
               <a href="/master/contribute" class="btn btn-lg btn-primary">
                  Learn More
               </a>
               <p style="padding-top:20px"> <a href="https://twitter.com/autogradelinux" class="twitter-follow-button"
                     data-show-count="false">Follow @autogradelinux</a></p>
            </div>
         </div>
         <div class="row">
            <div class="col-sm-9">
               <p class="copyright_text">
                  Copyright &copy; 2015-2018 Automotive Grade Linux Documentation, Licensed under the <a target="_blank"
                     href="http://www.apache.org/licenses/LICENSE-2.0">Apache License, Version 2.0</a>.
                  <br />
                  Automotive Grade Linux and logos are <a target="_blank" href="http://www.linuxfoundation.org">trademarks</a>
                  of The Linux Foundation.
                  <br />
                  Initial site design from <a href="https://cordova.apache.org/">Cordova website.</a> - warm thanks !
               </p>
            </div>
            <div class="col-sm-3">
               <small class="stats">Site rendered at: $(date --rfc-3339=seconds -u)</small>

            </div>
         </div>

      </div>
   </footer>
</body>

</html>
EOF

echo "Doc site is now available in $HTDOCS"
