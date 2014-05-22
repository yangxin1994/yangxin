/* Demo Note:  This demo uses a FileProgress class that handles the UI for displaying the file name and percent complete.
The FileProgress class is not part of SWFUpload.
*/

//=require ui/widgets/od_popup


/* **********************
   Event Handlers
   These are my custom event handlers to make my
   web application behave the way I went when SWFUpload
   completes different tasks.  These aren't part of the SWFUpload
   package.  They are part of my application.  Without these none
   of the actions SWFUpload makes will show up in my application.
   ********************** */
function fileQueued(file) {
    try {
        var progress = new FileProgress(file, this.customSettings.progressTarget);
        progress.setStatus("Pending...");
        progress.toggleCancel(true, this);

    } catch (ex) {
        this.debug(ex);
    }

}

function fileQueueError(file, errorCode, message) {
    try {
        if (errorCode === SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED) {
            alert("You have attempted to queue too many files.\n" + (message === 0 ? "You have reached the upload limit." : "You may select " + (message > 1 ? "up to " + message + " files." : "one file.")));
            return;
        }

        var progress = new FileProgress(file, this.customSettings.progressTarget);
        progress.setError();
        progress.toggleCancel(false);

        switch (errorCode) {
            case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
                progress.setStatus("File is too big.");
                this.debug("Error Code: File too big, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
            case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
                progress.setStatus("Cannot upload Zero Byte files.");
                this.debug("Error Code: Zero byte file, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
            case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
                progress.setStatus("Invalid File Type.");
                this.debug("Error Code: Invalid File Type, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
            default:
                if (file !== null) {
                    progress.setStatus("Unhandled Error");
                }
                this.debug("Error Code: " + errorCode + ", File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
        }
    } catch (ex) {
        this.debug(ex);
    }
}

function fileDialogStart() {

}

function fileDialogComplete(numFilesSelected, numFilesQueued) {
    try {
        var thisel = this;
        if (numFilesSelected > 0) {
            //update by GY
            beginUpload(true, this);
            //end update
        }
        /* I want auto start the upload and I can do that here */
        this.startUpload();

    } catch (ex) {
        this.debug(ex);
    }
}

function uploadStart(file) {
    try {
        /* I don't want to do any file validation or anything,  I'll just update the UI and
		return true to indicate that the upload should start.
		It's important to update the UI here because in Linux no uploadProgress events are called. The best
		we can do is say we are uploading.
		 */
        var progress = new FileProgress(file, this.customSettings.progressTarget);
        progress.setStatus("Uploading...");
        progress.toggleCancel(true, this);

    } catch (ex) {}

    return true;
}

function uploadProgress(file, bytesLoaded, bytesTotal) {
    try {
        var percent = Math.ceil((bytesLoaded / bytesTotal) * 100);

        var progress = new FileProgress(file, this.customSettings.progressTarget);

        progress.setProgress(percent);
        progress.setStatus("Uploading...");
    } catch (ex) {
        this.debug(ex);
    }
}

function uploadSuccess(file, serverData) {
    try {
        var progress = new FileProgress(file, this.customSettings.progressTarget);
        progress.setComplete();
        progress.setStatus("Complete.");
        //update by GY
        //存入数据库
        beginUpload(false, this);
        if (this.customSettings.fileType) { //上传图片、视频、音频
            postInfo(serverData, file.name, this.customSettings.fileType, serverData);
        } else {
            var sdata = JSON.parse(serverData);
            console.log(sdata);
            if (sdata.success) {
                var cont = "您成功导入" + sdata.value.insert_count + "条，更新" + sdata.value.updated_count + "条数据<br>";

                if (sdata.value.error.length != 0) {
                    cont += ("以下数据导入失败：<a href=\"/" + sdata.value.error + "\" target=\"_blank\">点击查看</a>");
                }
                $.od.odPopup({
                    content: cont,
                    size: {
                        width: 300
                    },
                    contentPosition: 'left',
                    confirm: function() {
                        window.location.reload();
                    }
                });
            } else {
                $.od.odPopup({
                    content: "导入数据失败！"
                });
            }
        }

        progress.toggleCancel(false);
    } catch (ex) {
        this.debug(ex);
    }
}

function postInfo(finfo, ftitle, ftype, fpic) {

    // 1 for image, 2 for video, 4 for audio
    if (parseInt(ftype) == 2) {
        finfo = JSON.parse(finfo);
        fpic = JSON.parse(fpic);
        finfo = finfo['val'] ? finfo['val'] : finfo;
        fpic = fpic['pic'] ? fpic['pic'] : fpic;
    }

    var param = {
        material: {
            value: finfo, //视频、音频11位码
            title: ftitle,
            material_type: ftype,
            picture_url: fpic
        }
    };
    var this_swf = this;
    $.postJSON("/utility/materials.json", param, function(retval) {
        console.log(retval);
        if (retval.success) {
            $('.od-uploadtip .pagination .firstPage').trigger('myclick', retval.value);
            //调整高度
            var h = $('.od-uploadtip').find('.layer_main').height() + 10;
            $('.od-uploadtip').find('.layer_bg').css('height', h);
            console.log('success: add ' + ftitle + ' !');
        } else {
            console.log('error: add ' + ftitle + ' !');
        }
    });
}

function uploadError(file, errorCode, message) {
    try {
        var progress = new FileProgress(file, this.customSettings.progressTarget);
        progress.setError();
        progress.toggleCancel(false);
        //update by GY
        beginUpload(false, this);
        //end update
        switch (errorCode) {
            case SWFUpload.UPLOAD_ERROR.HTTP_ERROR:
                progress.setStatus("Upload Error: " + message);
                this.debug("Error Code: HTTP Error, File name: " + file.name + ", Message: " + message);
                break;
            case SWFUpload.UPLOAD_ERROR.UPLOAD_FAILED:
                progress.setStatus("Upload Failed.");
                this.debug("Error Code: Upload Failed, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
            case SWFUpload.UPLOAD_ERROR.IO_ERROR:
                progress.setStatus("Server (IO) Error");
                this.debug("Error Code: IO Error, File name: " + file.name + ", Message: " + message);
                break;
            case SWFUpload.UPLOAD_ERROR.SECURITY_ERROR:
                progress.setStatus("Security Error");
                this.debug("Error Code: Security Error, File name: " + file.name + ", Message: " + message);
                break;
            case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
                progress.setStatus("Upload limit exceeded.");
                this.debug("Error Code: Upload Limit Exceeded, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
            case SWFUpload.UPLOAD_ERROR.FILE_VALIDATION_FAILED:
                progress.setStatus("Failed Validation.  Upload skipped.");
                this.debug("Error Code: File Validation Failed, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
            case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
                // If there aren't any files left (they were all cancelled) disable the cancel button
                if (this.getStats().files_queued === 0) {
                    document.getElementById(this.customSettings.cancelButtonId).disabled = true;
                }
                progress.setStatus("Cancelled");
                progress.setCancelled();
                break;
            case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
                progress.setStatus("Stopped");
                break;
            default:
                progress.setStatus("Unhandled Error: " + errorCode);
                this.debug("Error Code: " + errorCode + ", File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
                break;
        }
    } catch (ex) {
        this.debug(ex);
    }
}

function uploadComplete(file) {
    if (this.getStats().files_queued == 0) {
        //		document.getElementById(this.customSettings.cancelButtonId).disabled = true;
    }
}

// This event comes from the Queue Plugin
function queueComplete(numFilesUploaded) {
    //	var status = document.getElementById("divStatus");
    //	status.innerHTML = numFilesUploaded + " file" + (numFilesUploaded === 1 ? "" : "s") + " uploaded.";
}

function beginUpload(uploading, thisel) {
    if (thisel.customSettings.fileType) {
        if (uploading) {
            //隐藏：右上角关闭，上传按钮，title显示区
            $('.od-uploadtip .popup_panel .btn_close2').hide();
            document.getElementById(thisel.settings.button_placeholder_id).style.visibility = "hidden";
            $('.od-uploadtip').find('.chosen-show').hide();
            //显示：临时上传按钮图片，进度条	
            $('.od-uploadtip').find('.upload-bar').show();
            $('.od-uploadtip').find('.temp-button').addClass("temp-btn-uploading").css("display", "inline-block");
            $('.od-uploadtip').addClass('uploading');
        } else {
            $('.od-uploadtip').removeClass('uploading');
            //显示:右上角关闭，上传按钮，title显示区
            $('.od-uploadtip .popup_panel .btn_close2').show();
            document.getElementById(thisel.settings.button_placeholder_id).style.visibility = "visible";
            $('.od-uploadtip').find('.chosen-show').show();
            //隐藏：临时上传按钮图片，进度条
            $('.od-uploadtip').find('.upload-bar').hide();
            $('.od-uploadtip').find('.temp-button').removeClass("temp-btn-uploading").hide();
            $('#' + thisel.customSettings.progressTarget).children().remove();
        }
    } else if (thisel.customSettings.importData) {
        if (uploading) {
            $('.od-import .before-upload').css('visibility', 'hidden');
            $('.od-import .import-data').show();
        } else {
            $('.od-popup').remove();
        }

    }
    //调整高度
    var h = $('.od-uploadtip').find('.layer_main').height() + 10;
    $('.od-uploadtip').find('.layer_bg').css('height', h);
}