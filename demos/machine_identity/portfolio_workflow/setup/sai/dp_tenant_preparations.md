**DP Tenant Preparations**

**Docs**  
[https://docs.cyberark.com/early-release/secure-ai-agents/content/secureai/introduction.htm](https://docs.cyberark.com/early-release/secure-ai-agents/content/secureai/introduction.htm)

**Roles**  
There are 2 roles:

1. Secure AI Admins  
2. Secure AI Builders

If SAI was already installed on the tenant it won’t have the “Secure AI Builders” role.  
Please re-install SAI **or** run this api:

POST https://{identity-id}.id.cyberark.cloud/roles/storerole  
body:  
{  
  "Name": "Secure AI Builders",  
  "Description": "This role gives rights to Secure AI Gateway Builders"  
}

* You can ask us for the Identity ID if needed

**Create SIA Mcp**  
In order to use SIA you would need to create it using API only.   
This is the api you should run:

POST https://{tenant-name}-aigw.cyberark.cloud/api/targets/mcp-servers  
Accept: application/x.targets.beta+json  
body:  
{  
      "name": "SIA\_DB\_MCP\_SERVER",  
      "description": "SIA DB Mcp",  
      "category": "DATABASES\_AND\_DATA\_STORES",  
      "source": {        "type": "CUSTOM"  
      },  
      "upstream": {  
        "url": "https://us-east-1-sia-db-mcp.adb.cyberark.cloud/mcp"  
      },  
      "authMethod": {  
        "type": "OAUTH2.1"  
      }  
    }

**MCP Inventory**  
Until entry will be shown in the left side under administration section, it is possible to enter the MCP inventory via the url: [https://{tenant-name}.cyberark.cloud/adminportal/aigw/mcp/inventory](https://{tenant-name}.cyberark.cloud/adminportal/aigw/mcp/inventory)  
eg: [https://aigw-poc.cyberark.cloud/adminportal/aigw/mcp/inventory](https://aigw-poc.cyberark.cloud/adminportal/aigw/mcp/inventory)

**Mcp Servers for testing**

1. Passthrough   
   1. Context7 \- [https://mcp.context7.com/mcp/oauth](https://mcp.context7.com/mcp/oauth)  
   2. Snowflake \-   
2. MCP Servers with no authentication method (with CyberArk as IDP)  
   1. [https://mcp.context7.com/mcp](https://mcp.context7.com/mcp) (choose “None”)  
3. SIA  
   1. Use the API above in order to create it.

**Known issues**

1. No “MCP servers” entry in the left sidebar.  
2. MCP Inventory filter doesn’t work  
3. Pre-Defined list doesn’t exist (will be there very soon).  
4. Context7 \+ OAUTH in Claude AI (Desktop/Web) isn’t working.