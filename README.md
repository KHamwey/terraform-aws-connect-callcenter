# terraform-aws-connect-callcenter

A free-tier-friendly Amazon Connect call center deployed via Terraform, built incrementally so each layer can be verified in the AWS Console before stacking the next.

## Architecture

```
PSTN Caller --> Phone Number --> Contact Flow (InboundMain)
                                      |
                                      |--> GetCustomerInput --> KylesWebsiteBot (Lex V2)
                                      |
                                      `--> TransferToQueue --> BasicQueue
                                                                    |
                                                                    +-- Hours: 24x7
                                                                    +-- RoutingProfile: BasicRoutingProfile
                                                                    `-- User: agent1 (SecurityProfile: CallCenterAgent)
```

Built on top of the [`aws-ia/amazonconnect/aws`](https://github.com/aws-ia/terraform-aws-amazonconnect) module (`~> 0.0.1`).

## Prerequisites

- AWS account with admin credentials configured: `aws sts get-caller-identity`
- Terraform >= 1.5
- An existing Amazon Lex bot named `KylesWebsiteBot`
- A region that supports Amazon Connect (default: `us-east-1`)

## First-time setup

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with real values (instance_alias must be globally unique)
terraform init
```

## Deployment checkpoints

The build is split into 5 `terraform apply` checkpoints. Each one progressively uncomments a section of `main.tf`.

### Apply #1 — bare instance

Initial `main.tf` already targets only the instance. Run:

```bash
terraform plan -out tfplan
terraform apply tfplan
```

Verify: AWS Console -> Amazon Connect -> instance appears, CCP login URL (`terraform output ccp_login_url`) loads in browser.

### Apply #2 — hours, queue, routing profile, security profile, user

Uncomment the `hours_of_operations`, `queues`, `routing_profiles`, `security_profiles`, and `users` blocks in `main.tf`. Apply.

Verify: Log in to CCP as `agent1` with `agent_password`. See "Available" toggle.

### Apply #3 — Lex bot wiring

Detect bot version first:

```bash
aws lexv2-models list-bots --region us-east-1 \
  --query "botSummaries[?botName=='KylesWebsiteBot']"
aws lex-models get-bots --region us-east-1 \
  --query "bots[?name=='KylesWebsiteBot']"
```

- **V1**: set `lex_bot_version = "V1"` in tfvars, uncomment `bot_associations` block, apply.
- **V2**: set `lex_bot_version = "V2"`, populate `lex_v2_bot_alias_arn`, uncomment the V2 IAM policy block. (V2 bots are referenced inside the contact flow JSON — there is no Connect-side association resource.)

### Apply #4 — contact flow

1. Build the flow in the Connect Console (drag-drop), Save, Publish
2. Export the JSON:
   ```bash
   aws connect describe-contact-flow \
     --instance-id $(terraform output -raw instance_id) \
     --contact-flow-id <flow-id-from-console-url> \
     --region us-east-1 \
     | jq -r '.ContactFlow.Content' > flows/inbound_main.json
   ```
3. Uncomment `contact_flows` block in `main.tf` and apply.

### Apply #5 — claim phone number (manual, in Console)

DID phone numbers cost ~$0.03/day. Claim only when you're ready to test:

1. Console -> Channels -> Phone numbers -> Claim a number -> DID -> US
2. Attach `InboundMain` flow
3. Call the number from your cell

Release the number when done to stop daily charges.

## Cleanup

```bash
terraform destroy
```

> **Heads up**: Connect resources like queues, hours, security profiles **cannot be deleted via the Connect API**. Terraform will get duplicate-name errors if you try to recreate them. Workaround:
>
> ```bash
> terraform state rm 'module.amazon_connect.aws_connect_queue.this["BasicQueue"]'
> ```
>
> Then delete (or rename) in the Console manually.

## Cost estimate (free tier, first 12 months)

| Resource | Free allowance | Notes |
|---|---|---|
| Connect inbound voice | 90 min/month | Then $0.018/min DID |
| Connect outbound voice | 30 min/month | Then $0.018/min + telco |
| Phone number (DID) | none | $0.03/day claimed |
| Lex V2 text | 10K req/month | First year |
| Lex V2 speech | 5K req/month | First year |

## License

MIT
