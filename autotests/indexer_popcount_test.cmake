# SPDX-FileCopyrightText: 2026 SonicDE contributors
# SPDX-License-Identifier: MIT

# Run the real indexer, including its validation of the compressed output.
foreach(count IN ITEMS 1 2 9 10 98 99 100 101 198 199 200 999)
    string(REPEAT "#pop" ${count} pops)
    math(EXPR chunks "${count} / 99")
    math(EXPR remainder "${count} % 99")
    string(REPEAT "#pop(99)" ${chunks} expected)
    if(remainder EQUAL 1)
        string(APPEND expected "#pop")
    elseif(remainder GREATER 1)
        string(APPEND expected "#pop(${remainder})")
    endif()

    foreach(attribute IN ITEMS context lineEndContext lineEmptyContext fallthroughContext)
        foreach(destination IN ITEMS "" "!Normal" "!Normal!Inner")
            string(REPLACE "!" "-" suffix "${destination}")
            set(directory "${TEST_DIR}/${count}-${attribute}${suffix}")
            file(MAKE_DIRECTORY "${directory}/compressed")
            if(attribute STREQUAL "context")
                set(context_attributes "lineEndContext=\"#stay\"")
                set(rule_context "${pops}${destination}")
            else()
                set(context_attributes "${attribute}=\"${pops}${destination}\"")
                set(rule_context "#pop")
            endif()
            file(WRITE "${directory}/deep.xml" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE language>
<language name=\"Deep Pop Test\" version=\"1\" kateversion=\"6.22\" section=\"Other\" extensions=\"*.deep-pop\">
<highlighting><contexts>
<context name=\"Normal\" attribute=\"Normal\" lineEndContext=\"#stay\"><DetectChar char=\"{\" context=\"Inner\" attribute=\"Symbol\"/></context>
<context name=\"Inner\" attribute=\"String\" ${context_attributes}><DetectChar char=\"{\" context=\"Inner\" attribute=\"Symbol\"/><DetectChar char=\"}\" context=\"${rule_context}\" attribute=\"Symbol\"/></context>
</contexts><itemDatas><itemData name=\"Normal\" defStyleNum=\"dsNormal\"/><itemData name=\"String\" defStyleNum=\"dsString\"/><itemData name=\"Symbol\" defStyleNum=\"dsOperator\"/></itemDatas></highlighting>
<general><keywords casesensitive=\"1\"/></general></language>
")
            file(WRITE "${directory}/listing.xml" "<RCC><qresource><file>${directory}/deep.xml</file></qresource></RCC>")
            execute_process(
                COMMAND "${INDEXER}" "${directory}/index.katesyntax" "${SCHEMA}" "${directory}/listing.xml" "${directory}/compressed"
                RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE error
            )
            if(NOT result EQUAL 0)
                message(FATAL_ERROR "Indexer failed for ${count} pops, ${attribute}, '${destination}': ${result}\n${output}${error}")
            endif()
            file(READ "${directory}/compressed/deep.xml" compressed)
            string(FIND "${compressed}" "${attribute}=\"${expected}${destination}\"" position)
            if(position EQUAL -1)
                message(FATAL_ERROR "Incorrect pop serialization for ${count} pops, ${attribute}, '${destination}':\n${compressed}")
            endif()
        endforeach()
    endforeach()
endforeach()
