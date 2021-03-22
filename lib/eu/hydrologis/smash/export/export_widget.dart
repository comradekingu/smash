/*
 * Copyright (c) 2019. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */
import 'dart:async';
import 'dart:io';

import 'package:dart_hydrologis_utils/dart_hydrologis_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smash/eu/hydrologis/smash/export/geopackage_export.dart';
import 'package:smash/eu/hydrologis/smash/export/gpx_kml_export.dart';
import 'package:smashlibs/smashlibs.dart';
import 'package:smash/eu/hydrologis/smash/export/gss_export.dart';
import 'package:smash/eu/hydrologis/smash/export/gtt_export.dart';
/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */
import 'package:smash/eu/hydrologis/smash/export/pdf_export.dart';
import 'package:smash/eu/hydrologis/smash/models/project_state.dart';

class ExportWidget extends StatefulWidget {
  ExportWidget({Key key}) : super(key: key);

  @override
  _ExportWidgetState createState() => new _ExportWidgetState();
}

class _ExportWidgetState extends State<ExportWidget> {
  int _pdfBuildStatus = 0;
  String _pdfOutPath = "";
  int _gpxBuildStatus = 0;
  String _gpxOutPath = "";
  int _kmlBuildStatus = 0;
  String _kmlOutPath = "";
  int _gpkgBuildStatus = 0;
  String _gpkgOutPath = "";

  Future<void> buildPdf(BuildContext context) async {
    var exportsFolder = await Workspace.getExportsFolder();
    var ts = TimeUtilities.DATE_TS_FORMATTER.format(DateTime.now());
    var outFilePath =
        FileUtilities.joinPaths(exportsFolder.path, "smash_pdf_export_$ts.pdf");
    var projectState = Provider.of<ProjectState>(context, listen: false);
    var db = projectState.projectDb;
    await PdfExporter.exportDb(db, File(outFilePath));

    setState(() {
      _pdfOutPath = outFilePath;
      _pdfBuildStatus = 2;
    });
  }

  Future<void> buildGeopackage(BuildContext context) async {
    var exportsFolder = await Workspace.getExportsFolder();
    var ts = TimeUtilities.DATE_TS_FORMATTER.format(DateTime.now());
    var outFilePath =
        FileUtilities.joinPaths(exportsFolder.path, "smash_export_$ts.gpkg");
    var projectState = Provider.of<ProjectState>(context, listen: false);
    var db = projectState.projectDb;
    String errorString =
        await GeopackageExporter.exportDb(db, File(outFilePath));

    if (errorString != null) {
      SmashDialogs.showWarningDialog(context, errorString);
      setState(() {
        _gpkgOutPath = "";
        _gpkgBuildStatus = 0;
      });
    } else {
      setState(() {
        _gpkgOutPath = outFilePath;
        _gpkgBuildStatus = 2;
      });
    }
  }

  Future<void> buildGpx(BuildContext context, bool doKml) async {
    var exportsFolder = await Workspace.getExportsFolder();
    var ts = TimeUtilities.DATE_TS_FORMATTER.format(DateTime.now());

    var ext = doKml ? "kml" : "gpx";

    var outFilePath =
        FileUtilities.joinPaths(exportsFolder.path, "smash_export_$ts.$ext");
    var projectState = Provider.of<ProjectState>(context, listen: false);
    var db = projectState.projectDb;
    await GpxExporter.exportDb(db, File(outFilePath), doKml);

    setState(() {
      if (doKml) {
        _kmlOutPath = outFilePath;
        _kmlBuildStatus = 2;
      } else {
        _gpxOutPath = outFilePath;
        _gpxBuildStatus = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("エクスポート"),
      ),
      body: ListView(children: <Widget>[
        ListTile(
            leading: _pdfBuildStatus == 0
                ? Icon(
                    MdiIcons.filePdf,
                    color: SmashColors.mainDecorations,
                  )
                : _pdfBuildStatus == 1
                    ? CircularProgressIndicator()
                    : Icon(
                        Icons.check,
                        color: SmashColors.mainDecorations,
                      ),
            title: Text("${_pdfBuildStatus == 2 ? 'PDF exported' : 'PDF'}"),
            subtitle: Text(
                "${_pdfBuildStatus == 2 ? _pdfOutPath : 'プロジェクトをPDFにエクスポート'}"),
            onTap: () {
              setState(() {
                _pdfOutPath = "";
                _pdfBuildStatus = 1;
              });
              buildPdf(context);
//              Navigator.pop(context);
            }),
        ListTile(
            leading: _gpxBuildStatus == 0
                ? Icon(
                    MdiIcons.mapMarker,
                    color: SmashColors.mainDecorations,
                  )
                : _gpxBuildStatus == 1
                    ? CircularProgressIndicator()
                    : Icon(
                        Icons.check,
                        color: SmashColors.mainDecorations,
                      ),
            title: Text("${_gpxBuildStatus == 2 ? 'GPX exported' : 'GPX'}"),
            subtitle: Text(
                "${_gpxBuildStatus == 2 ? _gpxOutPath : 'プロジェクトをGPXにエクスポート'}"),
            onTap: () {
              setState(() {
                _gpxOutPath = "";
                _gpxBuildStatus = 1;
              });
              buildGpx(context, false);
//              Navigator.pop(context);
            }),
        ListTile(
            leading: _kmlBuildStatus == 0
                ? Icon(
                    MdiIcons.googleEarth,
                    color: SmashColors.mainDecorations,
                  )
                : _kmlBuildStatus == 1
                    ? CircularProgressIndicator()
                    : Icon(
                        Icons.check,
                        color: SmashColors.mainDecorations,
                      ),
            title: Text("${_kmlBuildStatus == 2 ? 'KML exported' : 'KML'}"),
            subtitle: Text(
                "${_kmlBuildStatus == 2 ? _kmlOutPath : 'プロジェクトをKMLにエクスポート'}"),
            onTap: () {
              setState(() {
                _kmlOutPath = "";
                _kmlBuildStatus = 1;
              });
              buildGpx(context, true);
//              Navigator.pop(context);
            }),
        ListTile(
            leading: _gpkgBuildStatus == 0
                ? Icon(
                    MdiIcons.packageVariant,
                    color: SmashColors.mainDecorations,
                  )
                : _gpkgBuildStatus == 1
                    ? CircularProgressIndicator()
                    : Icon(
                        Icons.check,
                        color: SmashColors.mainDecorations,
                      ),
            title: Text(
                "${_gpkgBuildStatus == 2 ? 'Geopackage exported' : 'Geopackage'}"),
            subtitle: Text(
                "${_gpkgBuildStatus == 2 ? _gpkgOutPath : 'プロジェクトをGeopackageにエクスポート'}"),
            onTap: () async {
              setState(() {
                _gpkgOutPath = "";
                _gpkgBuildStatus = 1;
              });
              await buildGeopackage(context);
//              Navigator.pop(context);
            }),
        ListTile(
            leading: Icon(
              MdiIcons.cloudLock,
              color: SmashColors.mainDecorations,
            ),
            title: Text("GSS"),
            subtitle: Text("Geopaparazzi Survey Serverにエクスポート"),
            onTap: () {
              var projectState =
                  Provider.of<ProjectState>(context, listen: false);
              var db = projectState.projectDb;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => new GssExportWidget(db)));
            }),
        ListTile(
            leading: Icon(
              MdiIcons.cloudLock,
              color: Colors.red, //SmashColors.mainDecorations,
            ),
            title: Text("GTT"),
            subtitle: Text(
              "GeoTaskTrackerサーバにエクスポート",
            ),
            onTap: () {
              var projectState =
                  Provider.of<ProjectState>(context, listen: false);
              var db = projectState.projectDb;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => new GttExportWidget(db)));
            }),
      ]),
    );
  }
}
