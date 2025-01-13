
# Steps to Create a VPN User

1. SSH into the VPN server:
    ```bash
    ssh adminuser@vpn.server.ip -i ~/.ssh/privatvpnkey.pem
    ```
2. Switch to the root user:
    ```bash
    sudo su -
    ```
3. Run the VPN user creation script with the username (replace `andreyb` with the desired username):
    ```bash
    ./createuservpn.sh andreyb
    ```
    As a result, you will receive the path to the OpenVPN configuration file:
    ```
    Client configuration file created: /root/client-configs/andreyb.ovpn
    ```

4. Copy the content of the configuration file or transfer the file to your local machine using `scp`:
    - To display and copy the file content:
        ```bash
        cat /root/client-configs/andreyb.ovpn
        ```


5. Create a connection profile in the OpenVPN client using the configuration file.

---

## Notes
- Ensure you have proper permissions and access to the server and `.pem` file.
- Replace `andreyb` with the desired username for the VPN.
