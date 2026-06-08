// lib/features/auth/domain/models/employee_model.dart

class EmployeeModel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? image;
  bool? status;
  EmployeeRole? role;
  Map<String, bool>? moduleAccess;
  EmployeeVendor? vendor;

  EmployeeModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.image,
    this.status,
    this.role,
    this.moduleAccess,
    this.vendor,
  });

  EmployeeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    image = json['image'];
    status = json['status'];
    role = json['role'] != null ? EmployeeRole.fromJson(json['role']) : null;
    vendor =
        json['vendor'] != null ? EmployeeVendor.fromJson(json['vendor']) : null;

    if (json['module_access'] != null) {
      moduleAccess = {};
      (json['module_access'] as Map<String, dynamic>).forEach((key, value) {
        moduleAccess![key] = value == true;
      });
    }
  }

  /// Check if this employee has access to a module by key.
  /// Returns true if the module_access map says true for the key.
  bool hasAccess(String module) => moduleAccess?[module] == true;
}

class EmployeeRole {
  int? id;
  String? name;

  EmployeeRole({this.id, this.name});

  EmployeeRole.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}

class EmployeeVendor {
  int? id;
  String? fName;
  String? lName;
  String? shopName;
  String? shopLogo;

  EmployeeVendor(
      {this.id, this.fName, this.lName, this.shopName, this.shopLogo});

  EmployeeVendor.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    shopName = json['shop_name'];
    shopLogo = json['shop_logo'];
  }

  String get fullName => '${fName ?? ''} ${lName ?? ''}'.trim();
}
