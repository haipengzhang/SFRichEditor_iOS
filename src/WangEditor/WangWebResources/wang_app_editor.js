/**
 * Copyright (C) 2020 Wasabeef
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * See about document.execCommand: https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand
 */

const { SlateEditor, SlateTransforms, SlateText } = window.wangEditor

var RE = {};

RE.editor = editor;

RE.currentSelection = {
    "startContainer": 0,
    "startOffset": 0,
    "endContainer": 0,
    "endOffset": 0
};

editorConfig.onChange = (editor) => {
    RE.debug("editorConfig onChange");
}

RE.setHtml = function (contents) {
    RE.editor.setHtml(contents);
    //decodeURIComponent这个方法有bug
    //RE.editor.setHtml(decodeURIComponent(contents.replace(/\+/g, '%20')));
}

RE.getHtml = function () {
    return RE.editor.getHtml();
}

RE.getText = function () {
    return RE.editor.getText();
}

RE.setBaseTextColor = function (color) {
    RE.editor.style.color = color;
}

RE.setBaseFontSize = function (size) {
    RE.editor.style.fontSize = size;
}

RE.setPadding = function (left, top, right, bottom) {
    RE.editor.style.paddingLeft = left;
    RE.editor.style.paddingTop = top;
    RE.editor.style.paddingRight = right;
    RE.editor.style.paddingBottom = bottom;
}

RE.setBackgroundColor = function (color) {
    document.body.style.backgroundColor = color;
}

RE.setBackgroundImage = function (image) {
    RE.editor.style.backgroundImage = image;
}

RE.setWidth = function (size) {
    RE.editor.style.minWidth = size;
}

RE.setHeight = function (size) {
    RE.editor.style.height = size;
}

RE.setTextAlign = function (align) {
    RE.editor.style.textAlign = align;
}

RE.setVerticalAlign = function (align) {
    RE.editor.style.verticalAlign = align;
}

RE.setPlaceholder = function (placeholder) {
    editorConfig.placeholder = placeholder;
}

RE.setInputEnabled = function (inputEnabled) {
    if (inputEnabled) {
        editor.enable()
    } else {
        editor.disable()
    }
}

RE.undo = function () {
    RE.editor.undo()
}

RE.redo = function () {
    RE.editor.redo()
}

RE.setBold = function () {
    RE.debug("RE.setBold");
    var isTrue = SlateEditor.marks(RE.editor).bold
    if (isTrue) {
        RE.editor.removeMark('bold')
    } else {
        RE.editor.addMark('bold', true)
    }
}

RE.setItalic = function () {
    var isTrue = SlateEditor.marks(RE.editor).italic
    if (isTrue) {
        RE.editor.removeMark('italic')
    } else {
        RE.editor.addMark('italic', true)
    }
}

RE.setSubscript = function () {
    var isTrue = SlateEditor.marks(RE.editor).sub
    if (isTrue) {
        RE.editor.removeMark('sub')
    } else {
        RE.editor.addMark('sub', true)
    }
}

RE.setSuperscript = function () {
    var isTrue = SlateEditor.marks(RE.editor).sup
    if (isTrue) {
        RE.editor.removeMark('sup')
    } else {
        RE.editor.addMark('sup', true)
    }
}

RE.setStrikeThrough = function () {
    var isTrue = SlateEditor.marks(RE.editor).sup
    if (isTrue) {
        RE.editor.removeMark('through')
    } else {
        RE.editor.addMark('through', true)
    }
}

RE.setUnderline = function () {
    var isTrue = SlateEditor.marks(RE.editor).underline
    if (isTrue) {
        RE.editor.removeMark('underline')
    } else {
        RE.editor.addMark('underline', true)
    }
}

RE.setBullets = function () {
    SlateTransforms.setNodes(editor, {
        type: 'list-item',
        ordered: false, // 有序 true/无序false
        indent: undefined,
    })
}

RE.setNumbers = function () {
    SlateTransforms.setNodes(editor, {
        type: 'list-item',
        ordered: true, // 有序 true/无序false
        indent: undefined,
    })
}

RE.setTextColor = function (color) {
    RE.editor.addMark('color', color)
}

RE.setTextBackgroundColor = function (color) {
    RE.editor.addMark('bgColor', color)
}

RE.setFontSize = function (fontSize) {
    RE.editor.addMark('fontSize', fontSize)
}

RE.setHeading = function (heading) {
    SlateTransforms.setNodes(editor, {
        type: 'header' + heading,
    })
}

RE.setParagraph = function () {
    SlateTransforms.setNodes(editor, {
        type: 'paragraph',
    })
}

RE.setIndent = function () {
    SlateTransforms.setNodes(editor, {
        indent: '2em'
    })
}

RE.setOutdent = function () {
    SlateTransforms.setNodes(RE.editor, {
        indent: '0em'
    })
}

RE.setJustifyLeft = function () {
    SlateTransforms.setNodes(editor, {
        textAlign: 'left',
    })
}

RE.setJustifyCenter = function () {
    SlateTransforms.setNodes(editor, {
        textAlign: 'center',
    })
}

RE.setJustifyRight = function () {
    SlateTransforms.setNodes(editor, {
        textAlign: 'right',
    })
}

RE.setBlockquote = function () {
    document.execCommand('formatBlock', false, '<blockquote>');
}

RE.insertImage = function (url, alt) {
    var image = {
        type: 'image',
        src: url,
        style: {
            width: '100%'
        },
        children: [{ text: alt }]
    }
    RE.editor.insertNode(image);
    RE.editor.move(1);
}

RE.updateHeight = function() {
    var msg = "updateHeight://";
    window.webkit.messageHandlers.jsm.postMessage(msg);
}

// wang editor restoreSelection
RE.prepareInsert = function() {
    RE.backuprange();
};

RE.focusEditor = function() {
    RE.editor.focus();
};

RE.removeHighlight = function() {
    RE.editor.selectAll();
    RE.editor.removeMark("bgColor");
    RE.editor.removeMark("color");
}

RE.backuprange = function() {
    var selection = window.getSelection();
    if (selection.rangeCount > 0) {
        var range = selection.getRangeAt(0);
        RE.currentSelection = {
            "startContainer": range.startContainer,
            "startOffset": range.startOffset,
            "endContainer": range.endContainer,
            "endOffset": range.endOffset
        };
    }
};

RE.insertImageW = function (url, alt, width) {
    var image = {
        type: 'image',
        src: url,
        style: {
            width: width
        },
        children: [{ text: alt }]
    }
    RE.editor.insertNode(image)
}

RE.insertImageWH = function (url, alt, width, height) {
    var image = {
        type: 'image',
        src: url,
        style: {
            width: width,
            height: height
        },
        children: [{ text: alt }]
    }
    RE.editor.insertNode(image)
    RE.editor.move(1);
}

RE.insertVideo = function (url, alt) {
    var image = {
        type: 'video',
        src: url,
        style: {
            width: '100%',
        },
        children: [{ text: '' }]
    }
    RE.editor.insertNode(image)
}

RE.insertVideoW = function (url, width) {
    var image = {
        type: 'video',
        src: url,
        style: {
            width: width
        },
        children: [{ text: '' }]
    }
    RE.editor.insertNode(image)
}

RE.insertVideoWH = function (url, width, height) {
    var image = {
        type: 'video',
        src: url,
        style: {
            width: width,
            height: height
        },
        children: [{ text: '' }]
    }
    RE.editor.insertNode(image)
}

RE.insertAudio = function (url, alt) {
    var html = '<audio src="' + url + '" controls></audio><br>';
    RE.insertHTML(html);
}

RE.insertYoutubeVideo = function (url) {
    var html = '<iframe width="100%" height="100%" src="' + url + '" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><br>'
    RE.insertHTML(html);
}

RE.insertYoutubeVideoW = function (url, width) {
    var html = '<iframe width="' + width + '" src="' + url + '" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><br>'
    RE.insertHTML(html);
}

RE.insertYoutubeVideoWH = function (url, width, height) {
    var html = '<iframe width="' + width + '" height="' + height + '" src="' + url + '" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><br>'
    RE.insertHTML(html);
}

RE.insertHTML = function (html) {
    RE.restorerange();
    document.execCommand('insertHTML', false, html);
}

RE.insertLink = function (url, title) {
    var image = {
        type: 'link',
        url: url,
        target: title,
        children: [{ text: "title" }]
    }
    RE.editor.insertNode(image)
}

RE.setTodo = function (text) {
    var html = '<input type="checkbox" name="' + text + '" value="' + text + '"/> &nbsp;';
    document.execCommand('insertHTML', false, html);
}

RE.restorerange = function () {
    var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);
    selection.addRange(range);
}

RE.enabledEditingItems = function (e) {
    var items = [];
    if (document.queryCommandState('insertHorizontalRule')) {
        items.push('horizontalRule');
    }
    var msg = "re-state://" + items.join(',');
    window.webkit.messageHandlers.jsm.postMessage(msg);
}

RE.focus = function () {
    RE.editor.focus(true)
}

RE.blurFocus = function () {
    RE.editor.blur();
}

RE.removeFormat = function () {
    document.execCommand('removeFormat', false, null);
}

RE.editor.on('change', function () {
    var editStyle = SlateEditor.marks(RE.editor)
    var items = [];
    if (editStyle.bold) {
        items.push('bold');
    }
    if (editStyle.italic) {
        items.push('italic');
    }
    if (editStyle.sub) {
        items.push('subscript');
    }
    if (editStyle.sup) {
        items.push('superscript');
    }
    if (editStyle.underline) {
        items.push('underline');
    }
    if (editStyle.through) {
        items.push('through');
    }
    const fragment = editor.getFragment()
    if (fragment != null) {
        var type = fragment[0].type
        if (type == "header1") {
            items.push('H1');
        }
        if (type == "header2") {
            items.push('H2');
        }
        if (type == "header3") {
            items.push('H3');
        }
        if (type == "header4") {
            items.push('H4');
        }
        if (type == "header5") {
            items.push('H5');
        }
        if (type == "header6") {
            items.push('H6');
        }

        if (type == "list-item" && fragment[0].ordered == true) {
            items.push('orderedList');
        }
        if (type == "list-item" && fragment[0].ordered == false) {
            items.push('unorderedList');
        }
        var textAlign = fragment[0].textAlign
        if (textAlign == "center") {
            items.push('justifyCenter');
        }
        if (textAlign == "left") {
            items.push('justifyLeft');
        }
        if (textAlign == "right") {
            items.push('justifyRight');
        }
    }
    var msg = "change://" + items.join(',');
    window.webkit.messageHandlers.jsm.postMessage(msg);
})

// This will show up in the XCode console as we are able to push this into an NSLog.
RE.debug = function(msg) {
    window.webkit.messageHandlers.jsm.postMessage('debug://'+msg);
}

// 获取焦点
RE.getCaretYPosition = function() {
    /*
    const nodeEntries = SlateEditor.nodes(RE.editor, {
         match: (node) => {
            if (SlateElement.isElement(node)) {
                RE.debug("node.type = " + node.type);
                if (node.type === 'paragraph') {
                    return true; // 匹配 paragraph
                }
            }
            return false;
        },
        universal: true,
    });
    
    if (nodeEntries == null) {
        RE.debug('当前未选中的 paragraph');
    } else {
        for (let nodeEntry of nodeEntries) {
            const [node, path] = nodeEntry;
            RE.debug('选中了 paragraph 节点', node);
            RE.debug('节点 path 是', path);
        }
    }
    */
    
    /*
    RE.editor.restoreSelection();
    const containerTop = RE.editor.getEditableContainer().getBoundingClientRect().top;
    RE.debug("== getCaretYPosition containerTop = " + containerTop);
    const selectTop = RE.editor.getSelectionPosition();
    RE.debug("== getCaretYPosition selectTop = " + RE.editor.getSelectionPosition().top);
    // RE.editor.getEditableContainer().getBoundingClientRect()
    return containerTop + selectTop;
    */
    /*
    const nodeEntries = SlateEditor.nodes(RE.editor, {
        match: (node) => {          // JS syntax
            if (RE.editor.isText(node)) {
                return true;
            }
           return false;
       },
       universal: true,
    });

    if (nodeEntries == null) {
        RE.debug('当前未选中的 不是void类型')
    } else {
        RE.debug('当前未选中的 是void类型')
        return 0;
    }
    */
    RE.debug("== getCaretYPosition begin");
    var sel = window.getSelection();
    var range = sel.getRangeAt(0);
    var span = document.createElement('span');
    range.collapse(false);
    range.insertNode(span);
    var topPosition = span.offsetTop;
//    span.parentNode.removeChild(span); remove的话会导致问题，wangeditore没问题；
    RE.debug("== getCaretYPosition done = " + topPosition);
    return topPosition;
}




