from nullroute.core import *
from pprint import pprint
import requests
from requests.exceptions import HTTPError

class DevError(BaseException):
    pass

class CertCentralClient(object):
    # https://www.digicert.com/services/v2/documentation/authorization/authorization-list
    base = "https://www.digicert.com/services/v2"

    def __init__(self, account_id=None, api_key=None):
        self.account_id = account_id
        self.api_key = api_key

        self.ua = requests.Session()
        if api_key:
            self.ua.headers["X-DC-DEVKEY"] = api_key

        self._user = None

    def get(self, ep, *args, **kwargs):
        uri = self.base + ep
        Core.debug("fetching %r" % uri)
        resp = self.ua.get(uri, *args, **kwargs)
        resp.raise_for_status()
        return resp

    def post(self, ep, *args, **kwargs):
        uri = self.base + ep
        Core.debug("posting to %r" % uri)
        resp = self.ua.post(uri, *args, **kwargs)
        resp.raise_for_status()
        return resp

    def get_myself(self):
        if not self._user:
            resp = self.get("/user/me")
            self._user = resp.json()
        return self._user

    def get_default_container(self):
        return self.get_myself()["container"]["id"]

    def get_container_authorizations(self, container_id):
        return self.get("/authorization",
                        params={"container_id": container_id})

    def get_organizations(self):
        resp = self.get("/organization")
        data = resp.json()
        if data["page"]["total"] > 1:
            raise DevError("paging not yet implemented for %r" % data)
        return data["organizations"]

    def get_order(self, order_id):
        resp = self.get("/order/certificate/%s" % order_id)
        return resp.json()

    def get_order_certificate(self, order_id, format="p7b"):
        order = self.get_order(order_id)
        cert_id = order["certificate"]["id"]
        if order["product"]["type"] == "ssl_certificate":
            cert_name = order["certificate"]["common_name"]
            cert_names = order["certificate"]["dns_names"]
        elif order["product"]["type"] == "client_certificate":
            pass
        resp = self.get("/certificate/%s/download/format/%s" % (cert_id, format))
        return cert_name, resp.content

    def post_order(self, order_type, order_data):
        resp = self.post("/order/certificate/%s" % order_type, json=order_data)
        return resp.json()
