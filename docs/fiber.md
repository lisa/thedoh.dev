---
title: Replacing the Telus NH20A with an X-ONU-SFPP in a Dream Machine SE
parentcategory: "random-projects"
category: "networking"
description: |
  Replacing Telus NH20A with X-ONU-SFPP in a Dream Machine SE
---

# Replacing the Telus NH20A with an X-ONU-SFPP in a Dream Machine SE

⚠️ Disclaimer: I am not a network engineer, nor can I say that this will work for you. I do this for fun and wasn't taking very detailed notes. If you try to do this sort of thing in your own situation, don't come crying to me if something breaks. But like, I figured it out, so you might be able to, too. But still, don't complain if you break your toys. ⚠️

I recently acquired some new networking gear for the homelab ahead of Telus putting fibre internet into the building - a [Ubiquiti Dream Machine SE][udm-se] - which has a 10GbE fibre WAN link and a 2.5GbE copper WAN link. I was aware that it was possible to replace the ISP's ONT (Optical Network Terminal) with customer provisioned gear (such as the Dream Machine) with the various guides at [pon.wiki][pon-wiki].

But one problem with the process is that I didn't know what kind of ONT Telus would provision: the NH20A, or NH20T, or something else entirely, perhaps. I decided to wait until I had the new Internet service up and running before making any decisions about which [pon.wiki][pon-wiki] guide to follow (even though they all sort of boil down to pick one of two fancy SFP+ devices). If Telus decided to do something weird, I didn't want to be a couple hundred dollars in the hole.

So I had an opportunity to pre-configure the router in advance of the Telus install: Copper port (aka `eth8`) until I can get the fibre port (`eth9`) up. I chose to put them in active/passive configuration, with both ports set up as WAN (*not* LAN).

When the Telus install date comes, I'm able to put their device - it was the `NH20A` - into bridge mode and patch it right in to the copper port while I make the appropriate arrangements.

## Doing the Actual Replacement

I would be following the instructions on the [Masquerade as the Telus Communications Inc. NH20A or NH20T with the WAS-110 or X-ONU-SFPP][nh20a-x-onu-sfpp-guide] guide since that's what Telus provided me with. First thing was first: What sort of subscriber was I?

The Telus UI indicated that I was an `XGS-GPON` subscriber, because the link was provisioned to 10Gbit/10Gbit (and 1270nm wavelength), which is just fine. 

### Which SFP+ Module Should I Use?

I decided to purchase an [X-ONU-SFPP][x-onu-sfpp] instead of a [WAS-110][was-110], mainly because it was easier to find a vendor. They seem fairly identical, otherwise? They do the same thing, and they both get very warm.

There's two ways to go with it: Purchase the plain module all by its lonesome and then put the [8311 firmware][8311-firmware] on it myself, or purchase one from a VAR that has the firmware pre-flashed. While reading the instructions for the flashing, it kept saying how tedious it was to do this flashing, and I thought it was better to have it pre-flashed to save my own sanity. Besides, I have enough projects.

### Preparing Network Connectivity

The [X-ONU-SFPP][x-onu-sfpp] comes, by default, assigned the IP address `192.168.11.1/24`. My home network operates on a separate segment so I wouldn't be able to access it without some work. I though I would take the lazy path out and simply make another network (VLAN) in the Unifi console on that segment and then simply re-IP my computer so it can access as if both devices are on the same local network (because they are). I also need to set `eth9` to LAN mode because I want to access it via the LAN. I'll have to put it back to WAN mode later.

There are certainly better ways to do it, such as making another network and adding a route to the new network - or to the device individually. But like I said: lazy path out. And it worked, so leave me alone.

### Initial Setup

Once I had access to the device, I could fire up the [8311 Web UI][8311-web-ui] on the SFPP module and get to the first configuration, copying from [the guide][nh20a-x-onu-sfpp-guide].

I need to set up these values, which are taken from the [aforementioned guide][nh20a-x-onu-sfpp-guide]:


| Attribute                  | Value                         | Remarks         |
|----------------------------|-------------------------------|-----------------|
| PON Serial Number (ONT ID) | `ARCB-REDACTED`                 | # XGSPON S/N    |
| Equipment ID               | `NH20A`                         |                 |
| Hardware Version           | `PRV650AB-S-TS`                 |                 |
| Sync Circuit Pack Version  | ✅                            |                 |
| Software Version A         | `3FETA203h03703`                | Version listing |
| Software Version B         | `Unknown`                       | Version listing |
| MIB File                   | `/etc/mibs/prx300_1U_telus.ini` | PPTP            |

I did think it was weird that the guide is asking to set the `Software Version B` to a literal `Unknown`, but what do I know? I was also curious where the software version comes from anyways because that isn't visible in the `NH20A`'s console (unless I overlooked it somehow). Nevertheless, I set up these values. Obviously I'm not providing my actual serial number and have redacted it.

During the setup I also re-IP'd the [X-ONU-SFPP][x-onu-sfpp] so it was on my network segment because it's annoying to have to re-IP my computer every time I want to talk to it. Yeah, it would have been smarter to set up proper routing, but like I said: lazy path out.

And all I need to do is plug the fibre in and set `eth9` to back to WAN mode and see what happens: Nothing. No Internet connectivity and I immediately lose access to the [X-ONU-SFPP][x-onu-sfpp].

### Second Setup

Clearly there was a [misconfiguration](#initial-setup), with that `Unknown` standing out like a sore thumb. In my reading on this topic there's a lot of possible things that could be happening here. Some of them include: 

* Maybe I'm not a DHCP customer, but rather PPPoE? 
* Maybe I need to set a VLAN? 35? 40? 1?
* Maybe I have some bad settings (like that `Software Version B`), or some other misconfiguration?
* Maybe I have to set up that static route to the SFPP's address (`192.168.11.1`) I saw mentioned, but why, if it's on my same LAN segment?

Back on real Internet I could come up with a plan, and the first plan was to make certain I had all the correct values in the [SFPP's configuration][8311-web-ui]. I connected back to the Telus NH20A and double checked that I had everything for the configuration. No need for a VLAN, I know whether it's DHCP or PPPoE, and I'm solid on what value to use for the `Software Version B` setting.

And so I make sure everything is ready to test again, even setting up a static route to the [X-ONU-SFPP][x-onu-sfpp], just to cover my bases.

Second try: No joy. My devices behind the router don't have connectivity, which is weird because it sure seemed like the [Dream Machine SE][udm-se] itself had connectivity. I'm having to swap the port (`eth9`) back and forth from WAN to LAN but looking at the logs I'm seeing that the optics in the SFPP are successfully negotiating with Telus's infrastructure, which means that the problem lays between that device and the rest of my network.

There's a bunch of messing around with the settings before giving up for the day. Nothing works. I end the day with the [Accessing the ONT guide][access-ont-guide] open and knowing it was important, but not why. It was a good day with the homelab hobby. Learning (or, in this case, re-learning) new things.

### The Epiphany and The Fix

That night I was laying in bed and it hit me. The [Accessing the ONT guide][access-ont-guide] has this important text:

> **The ONT resides on the WAN side of your network, not the LAN.** These are distinct networks. In their final, functional state, these two IP address spaces **must be separate and unique** for the router to distinguish between them. Additionally, do not conflict the **ONT LCT IP** with your **Internet IP.** Your WAN interface must be configured to accommodate both.

Now it makes sense. This SFPP is not a part of my LAN, and so it was a mistake to even have it on the same network segment in the first place. Once that fell into place, the reason for the routes made sense.

The next morning I'm up early and I re-IP the SFPP (the ONT, if readers haven't figured that out yet) back to `192.168.11.1/24`, reboot it. Back in Unifi, I delete that old static route that didn't do anything and set up a new `Gateway`-type static route to the SFPP via the WAN port (`eth9`).

And it works!! But just for the [router][udm-se]. Whoops. The router can access things no problem. Behind the router is not so empowered. But I can access the SFPP at its `192.168.11.1` address, which is an improvement.

The very last thing that I had to do to fix the routing was to change the built-in `inet` route so that the interface was targeting the correct WAN interface (`eth9`). And the last thing was to do a similar thing for internal networks for ipv6 so that they're taking their ipv6 information from the correct WAN interface.

## Conclusion

The magic to all of this was finding the [Accessing the ONT guide][access-ont-guide] (it wasn't linked anywhere from the [NH20A replacement guide][nh20a-x-onu-sfpp-guide] and finally understanding that the SFPP exists on the WAN-side, not the LAN-side.

With the Telus equipment out of the way I now have a much smaller footprint, and one less thing to power (okay, sure, the [X-ONU-SFPP][x-onu-sfpp] also needs to be powered, but much less). The tradeoff is that I need to keep the setup going on my own and be prepared to put the Telus gear back into service if I need to engage their technical support channels because they won't care if I had been using my own gear for years. But for homelabbing this was quite a fun little project! Now I can carry on with some other projects...

[rpi-k8s-cluster]: ../kubernetes/raspi-k8s-cluster.md
[8311-firmware]: https://github.com/djGrrr/8311-was-110-firmware-builder
[8311-web-ui]: https://192.168.11.1/cgi-bin/luci/admin/8311/config
[nh20a-x-onu-sfpp-guide]: https://pon.wiki/guides/masquerade-as-the-tci-nh20a-nh20t-with-the-was-110/
[pon-wiki]: https://pon.wiki
[nh20a-web-ui]: http://192.168.1.254
[troubleshooting-guide]: https://pon.wiki/guides/troubleshoot-connectivity-issues-with-the-was-110-or-x-onu-sfpp
[access-ont-guide]: https://pon.wiki/guides/accessing-the-ont/
[route-image-message]: https://discord.com/channels/886329492438671420/1005613572505747608/1568061299680743475
[udm-se]: https://ca.store.ui.com/ca/en/products/udm-se
[x-onu-sfpp]: https://pon.wiki/xgs-pon/ont/potron-technology/x-onu-sfpp/
[was-110]: https://pon.wiki/xgs-pon/ont/bfw-solutions/was-110/
