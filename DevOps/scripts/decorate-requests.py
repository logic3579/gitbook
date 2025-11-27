#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import requests
import json


__all__ = [
    ""
]


class _ApiBase(object):

    def __init__(self, auth_header, api_host=None):
        self.auth_header = auth_header
        self.api_host = api_host
        self.endpoint = ''

    def _do(self, method, relative_path=None, **kwargs):
        """
        method:: put, get, post, delete
        """
        try:
            url = self.api_host + self.endpoint + \
                (relative_path if relative_path else "")
            res = requests.request(
                method,
                url,
                headers=self.auth_header,
                **kwargs
            )
            return res
        except Exception as err:
            return_data = {
                "code": 111,
                "msg": f"Exception: {err}"
            }
            return return_data


class CustomApi(_ApiBase):
    def __init__(self, auth_header, api_host=None):
        super(CustomApi, self).__init__(auth_header, api_host)
        self.endpoint = '/api/v1/xx'

    def action_post(self, p1, p2)
    data = json.dumps({
        "parameter1": p1,
        "parameter2": p2
    })

    resp = self._do("POST", data=data)
    return resp.json()
