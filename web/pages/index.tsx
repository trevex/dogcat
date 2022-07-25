import type { NextPage } from 'next'
import dynamic from "next/dynamic";
import Head from 'next/head'

const Game = dynamic(() => import("../components/Game"), {
    ssr: false,
});

const Home: NextPage = () => {
    return (
        <div>
            <Head>
                <title>DogCat</title>
                <meta name="description" content="Basically two-ended snake" />
                <link rel="icon" href="/favicon.ico" />
            </Head>

            <Game size={800} cells={25} />
        </div>
    )
}

export default Home
