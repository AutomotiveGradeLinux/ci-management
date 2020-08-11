        ######################################################################
        # /!\/!\/!\   DEPRECATED FALLBACK WAY TO BUILD AGL APPS /!\/!\/!\    #
        ######################################################################

        export isCMAKE=0
        export isMAKE=0
        export isQMAKE=0

        if test x"0" = x"$DONE" -a -f CMakeLists.txt; then
	    echo "DEBUG: fallback to cmake."
            rm -rf build || true
            mkdir build
            pushd build
            cmake ../
            make
            popd
            export isCMAKE=1
            export DONE=1
        fi
        if test x"0" = x"$DONE" -a -f Makefile ; then
	    echo "DEBUG: fallback to make"
            make
	    echo "DEBUG: make package"
            make package
            export isMAKE=1
            export DONE=1
        fi
        if test x"0" = x"$DONE" -a -f ${MYPROJECT}.pro; then
	    echo "DEBUG: fallback to qmake"
            qmake
	    echo "DEBUG: qmake: make"
            make
	    echo "DEBUG: qmake: make package"
            make package
            export isQMAKE=1
            export DONE=1
        fi
        ######################################################################
        # /!\/!\/!\                  Ends Here                  /!\/!\/!\    #
        ######################################################################
