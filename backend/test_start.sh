#!/bin/bash
exec daphne -b 0.0.0.0 -p $PORT pulse_backend.asgi:application
