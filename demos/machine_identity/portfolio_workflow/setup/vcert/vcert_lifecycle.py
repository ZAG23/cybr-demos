#!/usr/bin/env python3
"""
CyberArk Certificate Manager (VCert) — Full Certificate Lifecycle Demo

Demonstrates: request → retrieve → renew → revoke
Supports: CyberArk Certificate Manager SaaS, Self-Hosted (TPP), or fake mode
"""
import json
import os
import sys
import time

from vcert import (
    venafi_connection,
    CertificateRequest,
    KeyType,
    Authentication,
    RevocationRequest,
    SCOPE_CM,
)


def get_connection():
    """Create VCert connection based on environment variables."""
    api_key = os.environ.get("VCERT_API_KEY", "")
    tpp_url = os.environ.get("VCERT_TPP_URL", "")
    tpp_user = os.environ.get("VCERT_TPP_USER", "")
    tpp_password = os.environ.get("VCERT_TPP_PASSWORD", "")
    tpp_token = os.environ.get("VCERT_TPP_ACCESS_TOKEN", "")

    if api_key:
        print("[vcert] Connecting to CyberArk Certificate Manager SaaS")
        return venafi_connection(api_key=api_key), "saas"
    elif tpp_url and tpp_token:
        print(f"[vcert] Connecting to CyberArk Certificate Manager Self-Hosted: {tpp_url}")
        return venafi_connection(url=tpp_url, access_token=tpp_token), "tpp"
    elif tpp_url and tpp_user:
        print(f"[vcert] Connecting to CyberArk Certificate Manager Self-Hosted: {tpp_url}")
        return venafi_connection(url=tpp_url, user=tpp_user, password=tpp_password), "tpp"
    else:
        print("[vcert] No credentials configured — using fake connection for demo")
        return venafi_connection(fake=True), "fake"


def request_certificate(conn, zone, common_name, san_dns):
    """Request a new certificate."""
    print(f"\n[vcert] Requesting certificate: CN={common_name}")

    request = CertificateRequest(
        common_name=common_name,
        san_dns=san_dns,
    )
    request.key_type = KeyType(KeyType.RSA, 2048)

    zone_config = conn.read_zone_conf(zone)
    request.update_from_zone_config(zone_config)

    conn.request_cert(request, zone)
    print(f"[vcert] Request submitted (id: {request.id})")
    return request


def retrieve_certificate(conn, request):
    """Retrieve an issued certificate."""
    print(f"\n[vcert] Retrieving certificate (id: {request.id})")
    request.timeout = 180

    cert = conn.retrieve_cert(request)
    print("[vcert] Certificate retrieved successfully")

    # Display certificate details
    if cert.cert:
        lines = cert.cert.strip().split("\n")
        print(f"[vcert]   Certificate: {lines[0]}...{lines[-1]}")
    if cert.chain:
        print(f"[vcert]   Chain certificates: {len(cert.chain)}")

    return cert


def renew_certificate(conn, request):
    """Renew an existing certificate."""
    print(f"\n[vcert] Renewing certificate (id: {request.id})")

    new_request = CertificateRequest(cert_id=request.id)
    conn.renew_cert(new_request, reuse_key=False)

    timeout = time.time() + 180
    cert = None
    while time.time() < timeout:
        try:
            cert = conn.retrieve_cert(new_request)
            if cert:
                break
        except Exception:
            pass
        time.sleep(5)

    if cert:
        print("[vcert] Certificate renewed successfully")
    else:
        print("[vcert] Renewal pending (timeout reached — check CyberArk portal)")

    return cert, new_request


def revoke_certificate(conn, request, mode):
    """Revoke a certificate (TPP only)."""
    if mode != "tpp":
        print(f"\n[vcert] Revocation skipped (only supported on Self-Hosted/TPP, current mode: {mode})")
        return

    print(f"\n[vcert] Revoking certificate (id: {request.id})")
    revoke_req = RevocationRequest(
        req_id=request.id,
        reason=RevocationRequest.RevocationReasons.superseded,
        comments="Demo lifecycle — replaced by renewed certificate",
    )
    success = conn.revoke_cert(revoke_req)
    print(f"[vcert] Revocation successful: {success}")


def main():
    zone = os.environ.get("VCERT_ZONE", "Default")
    common_name = os.environ.get("VCERT_COMMON_NAME", "demo-workload.example.com")
    san_dns_str = os.environ.get("VCERT_SAN_DNS", common_name)
    san_dns = [s.strip() for s in san_dns_str.split(",")]
    action = sys.argv[1] if len(sys.argv) > 1 else "full"

    conn, mode = get_connection()

    if action in ("request", "full"):
        request = request_certificate(conn, zone, common_name, san_dns)
        cert = retrieve_certificate(conn, request)

    if action in ("renew", "full"):
        if action == "renew":
            # For standalone renew, need a cert_id from env
            cert_id = os.environ.get("VCERT_CERT_ID", "")
            if not cert_id:
                print("[vcert] VCERT_CERT_ID required for standalone renew")
                sys.exit(1)
            request = CertificateRequest(cert_id=cert_id)
        renewed_cert, new_request = renew_certificate(conn, request)

    if action in ("revoke", "full"):
        if action == "revoke":
            cert_id = os.environ.get("VCERT_CERT_ID", "")
            if not cert_id:
                print("[vcert] VCERT_CERT_ID required for standalone revoke")
                sys.exit(1)
            request = CertificateRequest(cert_id=cert_id)
        revoke_certificate(conn, request, mode)

    print("\n[vcert] Lifecycle demo complete")
    summary = {
        "mode": mode,
        "common_name": common_name,
        "san_dns": san_dns,
        "zone": zone,
        "actions": action,
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
