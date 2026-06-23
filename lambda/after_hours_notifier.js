const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

const ses = new SESClient({});

exports.handler = async (event) => {
  const toEmail = process.env.TO_EMAIL;
  const fromEmail = process.env.FROM_EMAIL;

  const attrs = event.Details?.ContactData?.Attributes || {};
  const name = attrs.caller_name || "(not provided)";
  const phone = attrs.caller_phone || "(not provided)";
  const message = attrs.caller_message || "(not provided)";
  const contactId = event.Details?.ContactData?.ContactId || "unknown";

  console.log("After-hours notification", { contactId, name, phone });

  if (!toEmail || !fromEmail) {
    console.error("Missing TO_EMAIL or FROM_EMAIL environment variables");
    return {};
  }

  const subject = `After-hours call: ${name}`;
  const body = [
    "New after-hours callback request from your Connect demo.",
    "",
    `Name:    ${name}`,
    `Phone:   ${phone}`,
    `Message: ${message}`,
    "",
    `Contact ID: ${contactId}`,
  ].join("\n");

  await ses.send(
    new SendEmailCommand({
      Source: fromEmail,
      Destination: { ToAddresses: [toEmail] },
      Message: {
        Subject: { Data: subject, Charset: "UTF-8" },
        Body: { Text: { Data: body, Charset: "UTF-8" } },
      },
    })
  );

  return {};
};
