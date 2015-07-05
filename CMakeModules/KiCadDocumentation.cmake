#
# Part of the KiCad ASCIIDOC Documentation Project
#
# (c)2015 KiCad Developers
# (c)2015 Brian Sidebotham <brian.sidebotham@gmail.com>
#

macro( KiCadDocumentation DOCNAME )

    # Add the cvpcb documentation targets
    add_custom_target( ${DOCNAME} ALL )
    add_custom_target( ${DOCNAME}_updatepo_all )

    # Get a list of all the doc chapters
    file( GLOB DOCCHAPTERFILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}_*.adoc )

    foreach( DOC ${DOCCHAPTERFILES} )
	# Generate only the chapter name rather than the complete filename
	string( REGEX REPLACE "${DOCNAME}_(.+)\\.adoc" "\\1" CNAME "${DOC}" )
	list( APPEND DOCCHAPTERS "${CNAME}" )
    endforeach()

    # If we're not building a specific language, glob all languages
    if( "${SINGLE_LANGUAGE}" STREQUAL "" )
        # Get a list of all po translation files so we know what languages can be built
        file( GLOB TRANSLATIONS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/po ${CMAKE_CURRENT_SOURCE_DIR}/po/*.po )

        # Add English to the translations, but we'll have to treat it as a special case
        # when generating a translation target
        list( APPEND TRANSLATIONS en )
    else()
        # Get a list of all po translation files so we know what languages can be built
        file( GLOB AVAILABLE RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/po ${CMAKE_CURRENT_SOURCE_DIR}/po/*.po )

        # Only add the language target if it is available. If this document hasn't been
        # translated into the required language, don't include it as a target. English
        # doesn't have a .po file and is always producable, so add it without any checks
        if( ${SINGLE_LANGUAGE} STREQUAL "en" )
            list( APPEND TRANSLATIONS "${SINGLE_LANGUAGE}" )
        else()
            foreach( L ${AVAILABLE} )
                if( "${L}" STREQUAL "${SINGLE_LANGUAGE}.po" )
                    # Only build the required language
                    list( APPEND TRANSLATIONS "${SINGLE_LANGUAGE}" )
                endif()
            endforeach()
        endif()
    endif()

    foreach( LANGUAGE ${TRANSLATIONS} )

	string( SUBSTRING "${LANGUAGE}" 0 2 LANGUAGE )

	if( "${LANGUAGE}" MATCHES "en" )
	    # No need to translate, so just make a renamed copy of the source instead such
	    # that we have the same source target as every other language
	    # This is made a target so that changes are reflected on subsequent builds!	
	    add_custom_target( ${DOCNAME}_translate_${LANGUAGE}
		COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}"
		COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/images ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/images
		COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}.adoc ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.adoc )
	else()
	    # Targets to update the translation files - include individual language targets
	    # as well as an "all" target. Do not include updating the translations in the
	    # default all target
	    add_custom_target( ${DOCNAME}_updatepo_${LANGUAGE}
		COMMAND ${PO4A_COMMAND}-updatepo -f asciidoc -v -M utf-8 -m ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}.adoc -p ${CMAKE_CURRENT_SOURCE_DIR}/po/${LANGUAGE}.po )
	
	    add_dependencies( ${DOCNAME}_updatepo_all ${DOCNAME}_updatepo_${LANGUAGE} )
	
	    add_custom_target( ${DOCNAME}_translate_${LANGUAGE}
		COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}"
	        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/images ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/images
		COMMAND ${PO4A_COMMAND}-translate -f asciidoc -a ${CMAKE_CURRENT_SOURCE_DIR}/po/addendum.${LANGUAGE} -A utf-8 -M utf-8 -m ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}.adoc -p ${CMAKE_CURRENT_SOURCE_DIR}/po/${LANGUAGE}.po -k -0 -l ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.adoc )
	endif()

	# Non-ascii languages needs some special treatments
	if( "${LANGUAGE}" MATCHES "ja" )
		add_dblatex_option( -b xetex -p ${CMAKE_CURRENT_SOURCE_DIR}/../style/dblatex-pdf-ja.xsl )
	endif()

	# Deal with chapters for all languages...
	foreach( CHAPTER ${DOCCHAPTERS} )
	    add_custom_target( ${DOCNAME}_translate_${CHAPTER}_${LANGUAGE}
		COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${DOCNAME}_${CHAPTER}.adoc
		${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}_${CHAPTER}.adoc )

	    add_dependencies( ${DOCNAME}_translate_${LANGUAGE} ${DOCNAME}_translate_${CHAPTER}_${LANGUAGE} )
	endforeach()

	# HTML Generation
	list( FIND BUILD_FORMATS "html" HTML_BUILD )
	if( NOT "${HTML_BUILD}" EQUAL "-1" )
            add_adoc_html_target( ${DOCNAME}_html_${LANGUAGE}
                    ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.adoc
                    ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.html
                    ${LANGUAGE} )

            add_dependencies( ${DOCNAME}_html_${LANGUAGE} ${DOCNAME}_translate_${LANGUAGE} )
            add_dependencies( ${DOCNAME} ${DOCNAME}_html_${LANGUAGE} )

            install( FILES ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.html DESTINATION ./${LANGUAGE}/${DOCNAME}/html )
            install( DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/images DESTINATION ./${LANGUAGE}/${DOCNAME}/html )
        endif()
	
	
	# PDF Generation
	list( FIND BUILD_FORMATS "pdf" PDF_BUILD )
	if( NOT "${PDF_BUILD}" EQUAL "-1" )
            add_adoc_pdf_target( ${DOCNAME}_pdf_${LANGUAGE}
                    ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.adoc
                    ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.pdf
                    ${LANGUAGE} )

            add_dependencies( ${DOCNAME}_pdf_${LANGUAGE} ${DOCNAME}_translate_${LANGUAGE} )
            add_dependencies( ${DOCNAME} ${DOCNAME}_pdf_${LANGUAGE} )

            install( FILES ${CMAKE_CURRENT_BINARY_DIR}/${LANGUAGE}/${DOCNAME}.pdf DESTINATION ./${LANGUAGE}/${DOCNAME}/pdf )
        endif()
    endforeach()

endmacro()
