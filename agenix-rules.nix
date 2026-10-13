let
  bob = "age1pq1h4tewr3mp707vxjcq9r240q8gup4h9wt35j9k4w0jf97tuuma3fu5ttxcvh0pn620qqydj57umk2ysme5fzlfsdx33l30das3rsgnl5z35a880syscysmqfqpvqjpa2fwuukkfmrv9le7p52jxkf67uxcc35p2xdx8pk3kn9ujjzwpvkczgypqkumzqujee4jlpxshjzza62hr3kd934c3gp39r9f962fha72wgvjcan6f3258yqdyfhg8y2f2xf3vr5wp3tsuk9qkk2wtd2v4tzyyas7smy77pqv3qg2zt5pdk0g9rxlq5s5jmsu94y9gat0y4fhnzjdcvwe2ztcg590zy9qz580prluy58wgkq7mcgj7ulgccw62ew9m9u2h790lu6cyg3c6uk6scrv2q8arntcj6pj22h9scxjahz6p4xjf3ndqn2zrwmh0mzjwzm3yt4amqns24ppkux9gkrjypvem99wzsnzgdrysk6h0tr4nrmmk6uhxzsrd56xenjqhnl5sllktqt08uu300htrgxejcdmwdh3dcfsva336a6hh7ekxkvl23a39talgzerlnqpc8e0f60fvsuuhxdxavs25qffd8y27wey46hxgr4ht53kh3ysh8kn8athdqj9j7w9ap3z2anj825nnzcg5h9s5d8kg2c89s2e2uy4r7xss7240z4lqykhzxskkqh2xfxfqqafpy8w6qxw92tz8fqtz3yqeyr9jvkn5srpuws5a0rtwpdqjfmeu44yupkfvvrwaqcr9f55e4ws5p8p49gfeffpf4nv2cvzzcu7fewk2qzlh24puk5wqx9sk3rfexy3xu8s8a5wrqkevntvccz6uyq4pyf5t5j2vwe2haa23zl2zgpe3spenmp95z838h96fnknmywumpeprwydfp65fgjuf8jf3eskr5c6hksr7cz3vkawdt8hjymphjnjy3j5nxfyjta9xed7a5svru6ry7fgwgayhprun89pmyw5vunzjykvr0scgrdx3kcngelg3urhmmc3n8drxhhnxzn8nzunv3qkqqmdu6vznuzlslrlv3ue6y45m3psnnek4pvv7q56czz9pu584xxfa0tglk599tzp5nes478wp8kq78ezpuzgw8sudur5gwtqpqgvq7xy0w30jcu6cg57e6qa3wpd7vxkt2p6uglu7rxxu5hcqfq93a880mtm3vq83v4d45xlwrt398qvcgagugwsxcre4n9al38cezas6dmccpvr43xhwj2td23nx8nn8grwqyg3mppqpx4eeggfckr8ve27qfkpcy8vjrf2cx6hfx493gv7w7l59dhp6j2aqdmnwldqmwc3wwm44tjv8z3qvxjdx4r2twesfnkng7fv79rqxe6xglchftkaztg53smnu26jy4f2vtg0f6zxpftaycxlg7gcf62t43g835xuzz3pwd9e6wxppzh9c7eyn2rnjx34cr5zgmqrtks2stjkm0yz9tes7cku7zy2ynknnjkgx8qc434pq46f7ytlewtqn3zkc59z09u3pw9cax22c2x05wcyjazkzcgupduu9cu8zgyhhqapw62ugrz3qfxch3xqepuvvfr0t857w4nvkqzk9sk27ck4uuh928849ulfzgl9a6egc4pjz08za3drvl3rfeeg0g6fx8y0wztymr7hf0dflqff4yj0uwmwdzs9q8zce5xfgtj9ad9eqsec808ytdgmphk5cyc5z38m0zt3mwhsesu233rp6dpeeg47ngq5u7vy58rpvz7ussmth49uy4cf8nx8shc7vnhcxgcvgtx9sxuvyc05u6gge79lq463k0ecvdvtmd8h4aqfeaw3ys9lpsa203xwsma5m2jwneeyrwur2tf6x2tv96xldpg46m3f6mqxemrdnht8hvnpztuuvdfks4y2s8uxxru";
  cooper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8vdxG5iXS9qVo2U9FKlqLVcj+KhWCzbPsaok+MCOiP";
in
{
  "secrets/bob/users/tomas-password.age".publicKeys = [ bob ];
  "secrets/bob/users/root-password.age".publicKeys = [ bob ];

  "secrets/bob/tailscale/api-key.age".publicKeys = [ bob ];
  "secrets/bob/acme/env.age".publicKeys = [ bob ];
  "secrets/bob/nas/smb-credentials.age".publicKeys = [ bob ];
  "secrets/bob/readeck/env.age".publicKeys = [ bob ];
  "secrets/bob/healthchecks/env.age".publicKeys = [ bob ];
  "secrets/bob/prometheus/snmp-env.age".publicKeys = [ bob ];
  "secrets/bob/paperless/admin-password.age".publicKeys = [ bob ];
  "secrets/bob/paperless/env.age".publicKeys = [ bob ];
  "secrets/bob/navidrome/env.age".publicKeys = [ bob ];

  "secrets/bob/authelia/postgres-password.age".publicKeys = [ bob ];
  "secrets/bob/authelia/jwt-secret.age".publicKeys = [ bob ];
  "secrets/bob/authelia/session-secret.age".publicKeys = [ bob ];
  "secrets/bob/authelia/storage-encryption-key.age".publicKeys = [ bob ];
  "secrets/bob/authelia/users.age".publicKeys = [ bob ];
  "secrets/bob/authelia/oidc-hmac-secret.age".publicKeys = [ bob ];
  "secrets/bob/authelia/oidc-issuer-private-key.age".publicKeys = [ bob ];

  "secrets/bob/grafana/admin-password.age".publicKeys = [ bob ];
  "secrets/bob/grafana/secret-key.age".publicKeys = [ bob ];
  "secrets/bob/grafana/authelia-password.age".publicKeys = [ bob ];

  "secrets/cooper/users/tomas-password.age".publicKeys = [ cooper ];
  "secrets/cooper/users/root-password.age".publicKeys = [ cooper ];
}
