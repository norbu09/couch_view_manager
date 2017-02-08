defmodule Views.User do

  def user_by_email do
    %{doc: "_design/user",
      db: "keen",
      view: "by_email",
      map: "function(doc) {\n  if(doc.type == \"user\"){\n    emit(doc.email, null);\n  }\n}"
    }
  end

  def user_is_admin do
    %{doc: "_design/user",
      db: "keen",
      view: "is_admin",
      map: "function(doc) {\n  if(doc.is_admin){\n    emit(doc.email, null);\n  }\n}"
    }
  end

  def user_sms_verify do
    %{doc: "_design/user",
      db: "keen",
      view: "sms_verify",
      map: "function(doc) { if(doc.type == \"sm_verification\" && !doc.used){\n    emit(doc.user, doc.token);\n  }\n}"
    }
  end

  def user_worker do
    %{doc: "_design/user",
      db: "keen",
      view: "worker",
      map: "function(doc) {\n  if(doc.type == \"user\" && doc.userType == \"worker\"){\n    emit(doc.email, null);\n  } \n }"
    }
  end
end
