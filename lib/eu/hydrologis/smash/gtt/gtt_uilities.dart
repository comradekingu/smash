import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smash/eu/hydrologis/smash/project/objects/notes.dart';
import 'package:smashlibs/smashlibs.dart';

class GttUtilities {
  static final String KEY_GTT_SERVER_URL = "key_gtt_server_url";
  static final String KEY_GTT_SERVER_USER = "key_gtt_server_user";
  static final String KEY_GTT_SERVER_PWD = "key_gtt_server_pwd";
  static final String KEY_GTT_SERVER_KEY = "key_gtt_server_apiKey";

  static Future<String> getApiKey() async {
    String retVal;

    String pwd = GpPreferences().getStringSync(KEY_GTT_SERVER_PWD);
    String usr = GpPreferences().getStringSync(KEY_GTT_SERVER_USER);
    String url =
        "${GpPreferences().getStringSync(KEY_GTT_SERVER_URL)}/my/account.json";

    try {
      Dio dio = NetworkHelper.getNewDioInstance();

      Response response = await dio.get(
        url,
        options: Options(
          headers: {
            "Authorization":
                "Basic " + Base64Encoder().convert("$usr:$pwd".codeUnits),
            "Content-Type": "application/json",
          },
        ),
      );

      debugPrint(
          "Code: ${response.statusCode} Response: ${response.data.toString()}");

      if (response.statusCode == 200) {
        Map<String, dynamic> r = response.data;
        retVal = r["user"]["api_key"];
      }
    } catch (exception) {
      debugPrint("API KEY Error: $exception");
    }

    return retVal;
  }

  static Future<List<Map<String, dynamic>>> getUserProjects() async {
    List<Map<String, dynamic>> retVal = [];

    String url = "${GpPreferences().getStringSync(KEY_GTT_SERVER_URL)}"
        "/projects.json?limit=100000000&include=enabled_modules";

    String apiKey = GpPreferences().getStringSync(KEY_GTT_SERVER_KEY);

    try {
      Dio dio = NetworkHelper.getNewDioInstance();

      Response response = await dio.get(
        url,
        options: Options(
          headers: {
            "X-Redmine-API-Key": apiKey,
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("Msg: ${response.statusMessage} Response Records: "
            "${response.data["total_count"]}");

        //retVal = response.data["projects"] as List<Map<String, dynamic>>;
        for (Map<String, dynamic> ret in response.data["projects"]) {
          for (Map<String, dynamic> module in ret["enabled_modules"]) {
            /**
             * getting only Projects with gtt_smash module enabled
             */
            if (module["name"] == "gtt_smash") {
              retVal.add(ret);
              break;
            }
          }
        }
      }
    } catch (exception) {
      debugPrint("User Projects Error: $exception");
    }
    return retVal;
  }

  static Future<String> getProjectForm(String projectId) async {
    String retVal = "";

    String url;

    if (projectId == null) {
      url = "${GpPreferences().getStringSync(KEY_GTT_SERVER_URL)}"
          "/smash/tags.json";
    } else {
      url = "${GpPreferences().getStringSync(KEY_GTT_SERVER_URL)}"
          "/projects/$projectId/smash/tags.json";
    }

    debugPrint("Import URL: $url ");

    String apiKey = GpPreferences().getStringSync(KEY_GTT_SERVER_KEY);

    try {
      Dio dio = NetworkHelper.getNewDioInstance();

      Response response = await dio.get(
        url,
        options: Options(
          headers: {
            "X-Redmine-API-Key": apiKey,
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("Msg: ${response.statusMessage} ");

        retVal = jsonEncode(response.data);
      }
    } catch (exception) {
      debugPrint("Import Project Forms Error: $exception");
    }
    return retVal;
  }

  static Future<Map<String, dynamic>> postImage(
      Uint8List imageBytes, String imageName) async {
    Map<String, dynamic> retVal = Map<String, dynamic>();

    String url = "${GpPreferences().getStringSync(KEY_GTT_SERVER_URL)}"
        "/uploads.json?filename=$imageName";

    String apiKey = GpPreferences().getStringSync(KEY_GTT_SERVER_KEY);

    try {
      Dio dio = NetworkHelper.getNewDioInstance();

      Response response = await dio.post(
        url,
        options: Options(
          headers: {
            "X-Redmine-API-Key": apiKey,
            "Content-Type": "application/octet-stream",
          },
        ),
        data: Stream.fromIterable(imageBytes.map((e) => [e])),
      );

      retVal = {
        "status_code": response.statusCode,
        "status_message": response.statusMessage,
        "status_data": response.data,
      };
    } catch (exception) {
      debugPrint("Image Error: $exception");
    }
    return retVal;
  }

  static Future<Map<String, dynamic>> postIssue(
      Map<String, dynamic> params) async {
    Map<String, dynamic> retVal = Map<String, dynamic>();

    String url = "${GpPreferences().getStringSync(KEY_GTT_SERVER_URL)}"
        "/issues.json";

    String apiKey = GpPreferences().getStringSync(KEY_GTT_SERVER_KEY);

    try {
      Dio dio = NetworkHelper.getNewDioInstance();

      Response response = await dio.post(
        url,
        options: Options(
          headers: {
            "X-Redmine-API-Key": apiKey,
            "Content-Type": "application/json",
          },
        ),
        data: params,
      );

      retVal = {
        "status_code": response.statusCode,
        "status_message": response.statusMessage,
      };
    } catch (exception) {
      debugPrint("Issue Error: $exception");
    }
    return retVal;
  }

  static int getPriorityId(String p, List<dynamic> arr) {
    int count = 1;

    for (Map<String, dynamic> a in arr) {
      if (p == a["item"]) {
        break;
      }
      count++;
    }
    return count;
  }

  static Map<String, dynamic> createIssue(
      Note note, String selectedProj, List<Map<String, dynamic>> uploads) {
    String geoJson = "{\"type\": \"Feature\",\"properties\": {},"
        "\"geometry\": {\"type\": \"Point\",\"coordinates\": "
        "[${note.lon}, ${note.lat}]}}";

    String projectId = selectedProj;
    String subject = note.text.isEmpty ? "SMASH issue" : note.text;
    String description =
        note.description.isEmpty ? "SMASH issue" : note.description;

    int trackerId = 3;
    int priorityId = 2;
    String isPrivate = "false";
    String startDate = "";
    String dueDate = "";

    List<Map<String, dynamic>> customFields = [];

    if (note.hasForm()) {
      final form = json.decode(note.form);

      String sectionName = form["sectionname"];
      String sectionDesc = form["sectiondescription"];

      if (sectionName != null && sectionName == "text note") {
        for (var f in form["forms"][0]["formitems"]) {
          if (f["key"] == "title") {
            subject = f["value"];
          }
          if (f["key"] == "description") {
            description = f["value"];
          }
        }
      } else if (sectionDesc != null && sectionDesc.contains("GTT")) {
        for (var f in form["forms"][0]["formitems"]) {
          String fKey = f["key"];

          switch (fKey) {
            case "project_id":
              projectId = f["value"] != null ? f["value"] : projectId;
              break;
            case "tracker_id":
              trackerId = int.parse(f["value"]);
              break;
            case "priority_id":
              //priorityId = getPriorityId(f["value"], f["values"]["items"]);
              priorityId = int.parse(f["value"]);
              break;
            case "is_private":
              isPrivate = f["value"];
              break;
            case "subject":
              subject = f["value"];
              break;
            case "description":
              description = f["value"];
              break;
            case "start_date":
              startDate = f["value"];
              break;
            case "due_date":
              dueDate = f["value"];
              break;
          }

          if (fKey.startsWith("cf_")) {
            Map<String, dynamic> customField = {
              "id": int.parse(fKey.substring(3)),
              "value": f["value"],
            };

            customFields.add(customField);
          }
        }
      } else {
        description = note.form;
      }
    }

    Map<String, dynamic> params = {
      "project_id": projectId,
      "priority_id": priorityId,
      "tracker_id": trackerId,
      "subject": subject,
      "description": description,
      "is_private": isPrivate,
      "start_date": startDate,
      "due_date": dueDate,
      "custom_fields": customFields,
      "geojson": geoJson,
      "uploads": uploads,
    };

    Map<String, dynamic> issue = {
      "issue": params,
    };

    debugPrint("Issue: ${issue.toString()}");

    return issue;
  }

  static Widget getResultTile(String name, String description,
      {bool isImport = false}) {
    return ListTile(
      leading: Icon(
        isImport ? SmashIcons.importIcon : SmashIcons.upload,
        color: SmashColors.mainDecorations,
      ),
      title: Text(name),
      subtitle: Text(description),
      onTap: () {},
    );
  }
}
