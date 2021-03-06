#' @export
#' @title add a plot output as vector graphics into a Word object
#' @description produces a vector graphics output from R plot instructions
#' and add the result in an Word document object produced
#' by \code{\link[officer]{read_docx}}.
#' @param x an \code{rdocx} object produced by \code{officer::read_docx}
#' @param code plot instructions
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
#' @param ... arguments passed on to \code{\link{dml_docx}}.
#' @importFrom officer body_add_xml docx_reference_img wml_link_images
#' @note
#' The function is maintained but using it
#' should be avoided: Word text boxes, the elements used to put text in a graphic,
#' are adding extra space on top and bottom of the shape. As there is no clear rule
#' available to handle that, it makes impossible to compute what should be the
#' exact position of a text. This can affect the whole rendering of the graphic.
#'
#' The function should then be considered as a failed experience. An
#' alternative is to use EMF format, this will not allow editing the graphic but
#' the display is made as vector graphic.
#' @examples
#' \donttest{
#' library(officer)
#' x <- read_docx()
#' x <- body_add_vg(x, code = barplot(1:5, col = 2:6) )
#' print(x, target = "vg.docx")
#' }
body_add_vg <- function( x, code, pos = "after", ... ){

  uid <- basename(tempfile(pattern = ""))
  img_directory = file.path(getwd(), uid )
  dml_file <- tempfile()

  pars <- list(...)

  pars$file <- dml_file
  pars$id <- 0L
  pars$last_rel_id <- x$doc_obj$relationship()$get_next_id() - 1
  pars$raster_prefix <- img_directory
  pars$standalone <- FALSE

  do.call("dml_docx", pars)

  tryCatch(code, finally = dev.off() )
  raster_files <- list.files(path = getwd(), pattern = paste0("^", uid, "(.*)\\.png$"), full.names = TRUE )
  xml_elt <- scan( dml_file, what = "character", quiet = T, sep = "\n" )
  xml_elt <- gsub(pattern = "<w:drawing>",
                  replacement = paste0("<w:p ",
                                       "xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\" ",
                                       "xmlns:wp=\"http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing\" ",
                                       "xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" ",
                                       "xmlns:wps=\"http://schemas.microsoft.com/office/word/2010/wordprocessingShape\" ",
                                       "xmlns:pic=\"http://schemas.openxmlformats.org/drawingml/2006/picture\" ",
                                       "xmlns:wpg=\"http://schemas.microsoft.com/office/word/2010/wordprocessingGroup\">",
                                       "<w:pPr/><w:r>",
                                       "<w:drawing>"),
                  x = xml_elt )
  xml_elt <- paste0(xml_elt, "</w:r></w:p>")

  if( length(raster_files)){
    x <- docx_reference_img(x, raster_files)
    xml_elt <- wml_link_images( x, xml_elt )
    unlink(raster_files)
  }

  body_add_xml(x = x, str = xml_elt, pos = pos)

}


